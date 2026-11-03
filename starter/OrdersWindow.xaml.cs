using System.Data;
using System.Windows;
using System.Windows.Controls;
namespace ShopDb;
public partial class OrdersWindow : Window
{
    // === Доступ сотрудника и загрузка списка
    private readonly Repository repository;
    private bool busy;
    private long? loadedOrder;
    private int loadVersion;
    public OrdersWindow(Repository repository)
    {
        InitializeComponent();
        this.repository = repository;
        Title = repository.Settings.Company + " — Заказы";
        UserText.Text = repository.User?.Fio;
        ChangeDateButton.IsEnabled = repository.User?.IsAdmin == true;
        DeleteLineButton.IsEnabled = false;
        OrderDate.IsEnabled = repository.User?.IsAdmin == true;
    }
    private async void LoadedWindow(object sender, RoutedEventArgs e) => await Ui.Run(this, Reload);
    private long SelectedOrder => OrderGrid.SelectedItem is DataRowView row
        ? Convert.ToInt64(row["order_id"])
        : throw new InvalidOperationException("Выберите заказ в верхней таблице.");
    private async Task Reload()
    {
        ClearLines();
        OrderGrid.ItemsSource = (await repository.Orders()).DefaultView;
    }
    private void ClearLines()
    {
        loadVersion++;
        loadedOrder = null;
        LineGrid.SelectedItem = null;
        LineGrid.ItemsSource = null;
        DeleteLineButton.IsEnabled = false;
    }
    private async void OrderChanged(object sender, SelectionChangedEventArgs e) => await Ui.Run(this, async () =>
    {
        ClearLines();
        int version = loadVersion;
        if (OrderGrid.SelectedItem is DataRowView row)
        {
            long id = Convert.ToInt64(row["order_id"]);
            OrderDate.SelectedDate = Convert.ToDateTime(row["ordered_at"]);
            DataTable lines = await repository.Lines(id);
            if (version == loadVersion && OrderGrid.SelectedItem is DataRowView current && Convert.ToInt64(current["order_id"]) == id)
            {
                LineGrid.ItemsSource = lines.DefaultView;
                loadedOrder = id;
                DeleteLineButton.IsEnabled = repository.User?.IsAdmin == true;
            }
        }
        else
        {
            OrderDate.SelectedDate = null;
        }
    });
    // === Подтверждение необратимых действий и обновление
    private async Task Mutate(Func<Task> action)
    {
        if (busy)
        {
            return;
        }
        busy = true;
        IsEnabled = false;
        try
        {
            await Ui.Run(this, action);
        }
        finally
        {
            IsEnabled = true;
            busy = false;
        }
    }
    private async void DeleteOrderClick(object sender, RoutedEventArgs e) => await Mutate(async () =>
    {
        await Task.CompletedTask; MessageBox.Show(this,"Реализовать по методике: DeleteOrderClick.","Этап работы");
    });
    private async void DeleteLineClick(object sender, RoutedEventArgs e) => await Mutate(async () =>
    {
        await Task.CompletedTask; MessageBox.Show(this,"Реализовать по методике: DeleteLineClick.","Этап работы");
    });
    private async void ChangeDateClick(object sender, RoutedEventArgs e) => await Mutate(async () =>
    {
        await Task.CompletedTask; MessageBox.Show(this,"Реализовать по методике: ChangeDateClick.","Этап работы");
    });
    private async void RefreshClick(object sender, RoutedEventArgs e) => await Ui.Run(this, Reload);
    private void NewClick(object sender, RoutedEventArgs e) => DialogResult = true;
    private void BackClick(object sender, RoutedEventArgs e) => DialogResult = false;
}
