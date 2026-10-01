-- Исправление классификации собственной копии учебной БД.
-- Для новой БД из baseline.sql повторное применение не требуется.
-- Сохраните резервную копию; выберите свою рабочую БД перед выполнением.
START TRANSACTION;
UPDATE product p JOIN manufacturer m ON m.manufacturer_id=p.manufacturer_id JOIN category c ON c.name='Чемоданы' JOIN subcategory sc ON sc.category_id=c.category_id AND sc.name='Основной ассортимент' SET p.name='Чемодан тканевый',p.subcategory_id=sc.subcategory_id WHERE p.name='Чемодан тканевый' AND m.name='Учебная фабрика';
UPDATE product p JOIN manufacturer m ON m.manufacturer_id=p.manufacturer_id JOIN category c ON c.name='Сумки' JOIN subcategory sc ON sc.category_id=c.category_id AND sc.name='Основной ассортимент' SET p.name='Сумка дорожная — облегчённая модель',p.subcategory_id=sc.subcategory_id WHERE p.name='Сумка дорожная — облегчённая модель' AND m.name='Учебная фабрика';
COMMIT;
SELECT p.product_id,p.name,c.name AS category FROM product p JOIN subcategory sc USING(subcategory_id) JOIN category c USING(category_id) ORDER BY p.product_id;
