using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using MySqlConnector;
namespace ShopDb;
public partial class MainWindow : Window
{
    // === Состояние окна и первоначальная загрузка
    private Repository? repository;
    private List<Product> products = new();
    private readonly ObservableCollection<CartLine> cart = new();
    private string requestKey = Guid.NewGuid().ToString();
    private bool pending;
    private bool busy;
    public MainWindow()
    {
        InitializeComponent();
        CartList.ItemsSource = cart;
    }
    private async void LoadedWindow(object sender, RoutedEventArgs e) => await Ui.Run(this, async () =>
    {
        repository = new Repository();
        Title = repository.Settings.Company + " — Каталог";
        await RefreshCatalog();
    });
    private Repository Repo => repository ?? throw new InvalidOperationException("Проверьте настройки и перезапустите приложение.");
    private async Task RefreshCatalog()
    {
        products = await Repo.Catalog();
        long selected = (CategoryBox.SelectedItem as Choice)?.Id ?? 0;
        CategoryBox.ItemsSource = new[] { new Choice(0, "Все категории") }
            .Concat(products.Select(p => new Choice(p.CategoryId, p.Category)).Distinct()).ToList();
        CategoryBox.SelectedItem = ((List<Choice>)CategoryBox.ItemsSource)
            .FirstOrDefault(c => c.Id == selected) ?? ((List<Choice>)CategoryBox.ItemsSource)[0];
        ApplyFilter();
    }
    // === Фильтрация и сортировка одной выборки
    private void ApplyFilter()
    {
        if (CatalogList is null || CategoryBox is null || SortBox is null || SearchBox is null)
        {
            return;
        }
        IEnumerable<Product> view = products;
        if (repository?.User is not null)
        {
            string search = SearchBox.Text.Trim();
            long category = (CategoryBox.SelectedItem as Choice)?.Id ?? 0;
            view = view.Where(p => (category == 0 || p.CategoryId == category)
                && (p.Name.Contains(search, StringComparison.OrdinalIgnoreCase)
                    || p.Description.Contains(search, StringComparison.OrdinalIgnoreCase)));
            view = SortBox.SelectedIndex switch
            {
                1 => view.OrderBy(p => p.FinalPrice).ThenBy(p => p.Id),
                2 => view.OrderByDescending(p => p.FinalPrice).ThenBy(p => p.Id),
                _ => view.OrderBy(p => p.Id)
            };
        }
        List<Product> result = view.ToList();
        CatalogList.ItemsSource = result;
        StatusText.Text = $"Показано моделей: {result.Count} из {products.Count}. Двойной щелчок открывает карточку.";
    }
    private void FilterChanged(object sender, TextChangedEventArgs e) => ApplyFilter();
    private void SelectionChanged(object sender, SelectionChangedEventArgs e) => ApplyFilter();
    // === Смена пользователя и доступных действий
    private async void LoginClick(object sender, RoutedEventArgs e) => await Ui.Run(this, async () =>
    {
        if (busy || pending)
        {
            throw new InvalidOperationException("Завершите подтверждение текущего заказа перед сменой пользователя.");
        }
        await Repo.Login(LoginBox.Text);
        ClearCart();
        UpdateUser();
        await LoadCustomers();
        await RefreshCatalog();
    });
    private void UpdateUser()
    {
        UserText.Text = Repo.User?.Fio ?? "Гость";
        FilterPanel.IsEnabled = Repo.User is not null;
        LoginButton.Visibility = Repo.User is null ? Visibility.Visible : Visibility.Collapsed;
        LogoutButton.Visibility = Repo.User is null ? Visibility.Collapsed : Visibility.Visible;
        OrdersButton.Visibility = Repo.User?.IsStaff == true ? Visibility.Visible : Visibility.Collapsed;
        CustomerBox.IsEnabled = Repo.User?.IsStaff == true;
        UpdateCart();
    }
    private async Task LoadCustomers()
    {
        CustomerBox.ItemsSource = await Repo.Customers();
        CustomerBox.SelectedItem = ((List<Choice>)CustomerBox.ItemsSource)
            .FirstOrDefault(c => c.Id == Repo.User!.Id);
    }
    private void LogoutClick(object sender, RoutedEventArgs e)
    {
        if (busy || pending)
        {
            MessageBox.Show(this, "Сначала повторите подтверждение текущего заказа.", "Информация", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }
        Repo.Logout();
        ClearCart();
        CustomerBox.ItemsSource = null;
        UpdateUser();
        ApplyFilter();
    }
    // === Карточка модели и изменения корзины
    private void ProductClick(object sender, MouseButtonEventArgs e) => OpenProduct();
    private void OpenProductClick(object sender, RoutedEventArgs e) => OpenProduct();
    private async void OpenProduct() => await Ui.Run(this, async () =>
    {
        if (pending || busy)
        {
            throw new InvalidOperationException("Повторите подтверждение текущего заказа, прежде чем менять корзину.");
        }
        if (CatalogList.SelectedItem is not Product selected)
        {
            throw new InvalidOperationException("Сначала выберите модель в каталоге.");
        }
        Product current = (await Repo.Catalog()).Single(p => p.Id == selected.Id);
        var window = new ProductWindow(Repo, current) { Owner = this };
        if (window.ShowDialog() == true && window.Result is CartLine line)
        {
            CartLine? previous = cart.FirstOrDefault(c => c.ItemId == line.ItemId);
            if (previous is not null)
            {
                line = line with { Quantity = previous.Quantity + line.Quantity };
                SizeItem size = (await Repo.Sizes(current.Id)).Single(s => s.ItemId == line.ItemId);
                if (line.Quantity > size.Available)
                {
                    throw new InvalidOperationException("Суммарное количество в корзине превышает доступный остаток. Уменьшите количество выбранной позиции.");
                }
                cart.Remove(previous);
            }
            cart.Add(line);
            requestKey = Guid.NewGuid().ToString();
            UpdateCart();
        }
    });
    private void UpdateCart()
    {
        CartTotal.Text = $"Итого: {cart.Sum(c => c.Total):N2} ₽";
        CheckoutButton.IsEnabled = repository?.User is not null && cart.Count > 0 && !busy;
        RemoveCartButton.IsEnabled = !busy && !pending;
        ChangeCartButton.IsEnabled = !busy && !pending;
        CancelCartButton.IsEnabled = !busy && !pending;
        CustomerBox.IsEnabled = repository?.User?.IsStaff == true && !busy && !pending;
    }
    private void ClearCart()
    {
        cart.Clear();
        pending = false;
        requestKey = Guid.NewGuid().ToString();
        UpdateCart();
    }
    private void RemoveCartClick(object sender, RoutedEventArgs e)
    {
        if (!pending && !busy && CartList.SelectedItem is CartLine line)
        {
            cart.Remove(line);
            requestKey = Guid.NewGuid().ToString();
            UpdateCart();
        }
    }
    private void CancelCartClick(object sender, RoutedEventArgs e)
    {
        if (!pending && !busy)
        {
            ClearCart();
            StatusText.Text = "Неподтверждённый заказ отменён. БД не изменялась.";
        }
    }
    private void ChangeCartClick(object sender, RoutedEventArgs e)
    {
        if (busy || pending || CartList.SelectedItem is not CartLine line)
        {
            return;
        }
        if (!int.TryParse(CartQuantity.Text, out int quantity) || quantity < 1 || quantity > 999999)
        {
            MessageBox.Show(this, "Введите целое количество от 1 до 999999. Остаток будет проверен при подтверждении.", "Ошибка количества", MessageBoxButton.OK, MessageBoxImage.Error);
            return;
        }
        int index = cart.IndexOf(line);
        cart[index] = line with { Quantity = quantity };
        requestKey = Guid.NewGuid().ToString();
        UpdateCart();
    }
    // === Подтверждение и повтор с тем же ключом
    private async void CheckoutClick(object sender, RoutedEventArgs e)
    {
        if (busy || cart.Count == 0)
        {
            return;
        }
        busy = true;
        pending = true;
        UpdateCart();
        await Ui.Run(this, async () =>
        {
            if (CustomerBox.SelectedItem is not Choice customer)
            {
                pending = false;
                throw new InvalidOperationException("Выберите клиента заказа.");
            }
            long id;
            try
            {
                id = await Repo.Checkout(customer.Id, cart, requestKey);
            }
            catch (MySqlException error) when (error.SqlState == "45000" || error.Number is 1213 or 1205)
            {
                pending = false;
                throw;
            }
            ClearCart();
            await RefreshCatalog();
            StatusText.Text = $"Заказ №{id} сохранён. Остатки и цены каталога обновлены.";
        });
        busy = false;
        UpdateCart();
    }
    private async void RefreshClick(object sender, RoutedEventArgs e) => await Ui.Run(this, RefreshCatalog);
    private async void OrdersClick(object sender, RoutedEventArgs e) => await Ui.Run(this, async () =>
    {
        var window = new OrdersWindow(Repo) { Owner = this };
        if (window.ShowDialog() == true)
        {
            StatusText.Text = "Для нового заказа найдите товар и добавьте нужный размер в корзину.";
        }
        await RefreshCatalog();
    });
}
