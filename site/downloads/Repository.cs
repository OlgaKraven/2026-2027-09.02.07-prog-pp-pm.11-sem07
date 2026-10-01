using System.Data;
using System.IO;
using System.Text.Json;
using MySqlConnector;
namespace ShopDb;
public sealed class Repository
{
    // === Локальная конфигурация и параметризованная команда
    public Settings Settings { get; }
    public AppUser? User { get; private set; }
    private string Role => User?.Role ?? "login";
    public Repository()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "settings.local.json");
        Settings = JsonSerializer.Deserialize<Settings>(File.ReadAllText(path))
            ?? throw new InvalidOperationException("Не заполнены настройки подключения.");
        foreach (string key in new[] { "login", "client", "manager", "admin" })
        {
            if (!Settings.Connections.ContainsKey(key))
            {
                throw new InvalidOperationException($"В настройках отсутствует подключение {key}.");
            }
        }
    }
    private async Task<DataTable> Query(string sql, params (string Name, object Value)[] values)
    {
        await using var connection = new MySqlConnection(Settings.Connections[Role]);
        await connection.OpenAsync();
        await using var command = new MySqlCommand(sql, connection);
        command.CommandTimeout = 15;
        foreach (var value in values)
        {
            command.Parameters.AddWithValue(value.Name, value.Value);
        }
        await using var reader = await command.ExecuteReaderAsync();
        var table = new DataTable();
        table.Load(reader);
        return table;
    }
    // === Вход и чтение каталога
    public async Task Login(string login)
    {
        User = null;
        DataTable table = await Query("CALL pp_login(@login)", ("@login", login.Trim()));
        if (table.Rows.Count != 1)
        {
            throw new InvalidOperationException("Логин не найден. Проверьте написание по данным своего варианта.");
        }
        DataRow row = table.Rows[0];
        User = new AppUser(Convert.ToInt64(row["customer_id"]),
            Convert.ToString(row["fio"])!, Convert.ToString(row["role_name"])!);
    }
    public void Logout() => User = null;
    public async Task<List<Product>> Catalog()
    {
        DataTable table = await Query("CALL pp_catalog(@date)", ("@date", DateTime.Today));
        return table.Rows.Cast<DataRow>().Select(row => new Product(
            Convert.ToInt64(row["product_id"]), (string)row["name"],
            Convert.ToInt64(row["category_id"]), (string)row["category"],
            (string)row["manufacturer"], (string)row["composition"],
            (string)row["description"], (string)row["image_path"],
            (decimal)row["price"], (decimal)row["final_price"],
            Convert.ToInt32(row["available"]))).ToList();
    }
    public async Task<List<SizeItem>> Sizes(long product)
    {
        DataTable table = await Query("CALL pp_sizes(@product)", ("@product", product));
        return table.Rows.Cast<DataRow>().Select(row => new SizeItem(
            Convert.ToInt64(row["item_id"]), (string)row["label"],
            Convert.ToInt32(row["available"]))).ToList();
    }
    // === Заказ клиента и выбор клиента сотрудником
    private AppUser Actor => User ?? throw new InvalidOperationException("Сначала войдите по логину.");
    private void Staff()
    {
        if (!Actor.IsStaff)
        {
            throw new InvalidOperationException("Список заказов доступен менеджеру и администратору.");
        }
    }
    public async Task<List<Choice>> Customers()
    {
        if (!Actor.IsStaff)
        {
            return new List<Choice> { new(Actor.Id, Actor.Fio) };
        }
        DataTable table = await Query("CALL pp_customers(@actor)", ("@actor", Actor.Id));
        return table.Rows.Cast<DataRow>().Select(row => new Choice(
            Convert.ToInt64(row["customer_id"]), (string)row["fio"])).ToList();
    }
    public async Task<long> Checkout(long customer, IEnumerable<CartLine> lines, string key)
    {
        string json = JsonSerializer.Serialize(lines.Select(line => new
        {
            item_id = line.ItemId,
            quantity = line.Quantity
        }));
        DataTable table = await Query("CALL pp_checkout(@actor,@customer,@lines,@key)",
            ("@actor", Actor.Id), ("@customer", customer), ("@lines", json), ("@key", key));
        return Convert.ToInt64(table.Rows[0]["created_order"]);
    }
    // === Управление заказами через ограниченные процедуры
    public Task<DataTable> Orders()
    {
        Staff();
        return Query("CALL pp_orders(@actor)", ("@actor", Actor.Id));
    }
    public Task<DataTable> Lines(long order)
    {
        Staff();
        return Query("CALL pp_lines(@actor,@order)", ("@actor", Actor.Id), ("@order", order));
    }
    public Task<DataTable> DeleteOrder(long order)
    {
        Staff();
        return Query("CALL pp_delete_order(@actor,@order)", ("@actor", Actor.Id), ("@order", order));
    }
    private void Admin()
    {
        if (!Actor.IsAdmin)
        {
            throw new InvalidOperationException("Это действие доступно только администратору.");
        }
    }
    public Task<DataTable> DeleteLine(long order, long item)
    {
        Admin();
        return Query("CALL pp_delete_line(@actor,@order,@item)",
            ("@actor", Actor.Id), ("@order", order), ("@item", item));
    }
    public Task<DataTable> ChangeDate(long order, DateTime date)
    {
        Admin();
        return Query("CALL pp_change_date(@actor,@order,@date)",
            ("@actor", Actor.Id), ("@order", order), ("@date", date));
    }
}
