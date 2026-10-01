using System.Windows;
using MySqlConnector;
namespace ShopDb;
public static class Ui
{
    // === Понятное сообщение без строки подключения
    public static async Task Run(Window owner, Func<Task> action)
    {
        try
        {
            await action();
        }
        catch (MySqlException error)
        {
            string text = error.Message.Contains("NOT_ENOUGH_STOCK")
                ? "Остаток изменился. Обновите каталог и уменьшите количество в заказе."
                : error.Message.Contains("ROLE_DENIED") || error.Number == 1370
                ? "Действие запрещено для этой роли. Войдите с разрешённым логином."
                : error.Message.Contains("NOT_FOUND")
                ? "Заказ или строка уже удалены. Обновите список заказов."
                : error.Message.Contains("INVALID_DATE")
                ? "Дата не должна находиться в будущем. Выберите корректную дату."
                : error.Number == 1213 || error.Number == 1205
                ? "Данные сейчас изменяет другой пользователь. Повторите операцию с тем же заказом."
                : "Не удалось выполнить операцию с БД. Проверьте запуск MySQL, имя БД и локальные настройки. При неясном результате подтверждения повторите запрос, не изменяя корзину.";
            MessageBox.Show(owner, text, "Ошибка операции", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        catch (Exception error)
        {
            string text = error is InvalidOperationException or ArgumentException
                ? error.Message
                : "Проверьте settings.local.json и файлы ресурсов, затем повторите запуск.";
            MessageBox.Show(owner, text, "Ошибка данных", MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }
    public static bool Confirm(Window owner, string text) => MessageBox.Show(owner, text,
        "Подтверждение удаления", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes;
}
