-- === Разрешения для уже созданных локальных учётных записей
-- Выполняйте администратором; замените pp11_demo на имя своей учебной копии.
-- Пароли задавайте в phpMyAdmin, а не в этом файле или репозитории.
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_login TO 'pp11_demo_login'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_catalog TO 'pp11_demo_login'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_sizes TO 'pp11_demo_login'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_catalog TO 'pp11_demo_client'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_sizes TO 'pp11_demo_client'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_checkout TO 'pp11_demo_client'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_catalog TO 'pp11_demo_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_sizes TO 'pp11_demo_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_checkout TO 'pp11_demo_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_customers TO 'pp11_demo_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_orders TO 'pp11_demo_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_lines TO 'pp11_demo_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_delete_order TO 'pp11_demo_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_catalog TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_sizes TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_checkout TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_customers TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_orders TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_lines TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_delete_order TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_delete_line TO 'pp11_demo_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE pp11_demo.pp_change_date TO 'pp11_demo_admin'@'localhost';
