using System.Windows;
using System.Windows.Media.Imaging;
namespace ShopDb;
public partial class ProductWindow : Window
{
    // === Актуальные данные карточки
    private readonly Repository repository;
    private readonly Product product;
    public CartLine? Result { get; private set; }
    public ProductWindow(Repository repository, Product product)
    {
        InitializeComponent();
        this.repository = repository;
        this.product = product;
        Title = repository.Settings.Company + " — " + product.Name;
        NameText.Text = product.Name;
        DetailsText.Text = $"Категория: {product.Category}\nПроизводство: {product.Manufacturer}\nСостав: {product.Composition}\nОписание: {product.Description}";
        PriceText.Text = $"Цена со скидкой: {product.FinalPrice:N2} ₽";
        ProductImage.Source = new BitmapImage(new Uri(product.Picture));
    }
    private async void LoadedWindow(object sender, RoutedEventArgs e) => await Ui.Run(this, async () =>
    {
        List<SizeItem> sizes = await repository.Sizes(product.Id);
        SizesText.Text = "Размерный ряд: " + string.Join(", ", sizes.Select(s => s.Label));
        SizeBox.ItemsSource = sizes.Where(s => s.Available > 0).ToList();
        SizeBox.SelectedIndex = 0;
        AddButton.IsEnabled = repository.User is not null && SizeBox.Items.Count > 0;
    });
    // === Проверка выбора до изменения корзины
    private void AddClick(object sender, RoutedEventArgs e)
    {
        MessageBox.Show(this,"Реализовать по методике: AddClick.","Этап работы");
    }
    private void BackClick(object sender, RoutedEventArgs e) => DialogResult = false;
}
