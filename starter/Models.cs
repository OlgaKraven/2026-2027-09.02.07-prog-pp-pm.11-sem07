using System.IO;
namespace ShopDb;
// === Настройки и пользователь приложения
public sealed class Settings
{
    public string Company { get; set; } = "Магазин «Пара»";
    public Dictionary<string, string> Connections { get; set; } = new();
}
public sealed record AppUser(long Id, string Fio, string Role)
{
    public bool IsStaff => Role is "manager" or "admin";
    public bool IsAdmin => Role == "admin";
}
// === Модель каталога и товарная позиция
public sealed record Product(long Id, string Name, long CategoryId, string Category,
    string Manufacturer, string Composition, string Description, string ImagePath,
    decimal Price, decimal FinalPrice, int Available)
{
    public string StockLabel => Available > 5 ? "много" : "мало";
    public bool LowStock => Available <= 3;
    public string Picture
    {
        get
        {
            string path = Path.Combine(AppContext.BaseDirectory, "Assets", "Images",
                Path.GetFileName(ImagePath));
            return File.Exists(path) ? path : Path.Combine(AppContext.BaseDirectory,
                "Assets", "picture.png");
        }
    }
}
public sealed record SizeItem(long ItemId, string Label, int Available)
{
    public string Display => $"{Label} — доступно {Available}";
}
public sealed record Choice(long Id, string Name);
public sealed record CartLine(long ItemId, string Position, int Quantity, decimal Price)
{
    public decimal Total => Quantity * Price;
}
