-- Готовые компоненты входного комплекта. Выполнить целиком в рабочей копии.
-- === Дополнительные учебные пользователи для проверки всех ролей
INSERT INTO app_role(name) VALUES('Клиент'),('Менеджер'),('Администратор')
ON DUPLICATE KEY UPDATE name=VALUES(name);
INSERT INTO customer(login,last_name,first_name,patronymic,role_id)
SELECT 'pp_client','Учебный','Клиент','',role_id FROM app_role
WHERE name='Клиент' AND NOT EXISTS(SELECT 1 FROM customer WHERE login='pp_client');
INSERT INTO customer(login,last_name,first_name,patronymic,role_id)
SELECT 'pp_manager','Учебный','Менеджер','',role_id FROM app_role
WHERE name='Менеджер' AND NOT EXISTS(SELECT 1 FROM customer WHERE login='pp_manager');
INSERT INTO customer(login,last_name,first_name,patronymic,role_id)
SELECT 'pp_admin','Учебный','Администратор','',role_id FROM app_role
WHERE name='Администратор' AND NOT EXISTS(SELECT 1 FROM customer WHERE login='pp_admin');

-- === Миграция без изменения исторических цен
ALTER TABLE sales_order ADD COLUMN IF NOT EXISTS request_key CHAR(36) NULL;
ALTER TABLE sales_order ADD COLUMN IF NOT EXISTS created_by BIGINT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_order_request ON sales_order(request_key);
-- === Цена относительно календарного месяца
DROP FUNCTION IF EXISTS pp_price;
DELIMITER $$
CREATE FUNCTION pp_price(p_product BIGINT,p_date DATE)
RETURNS DECIMAL(12,2) READS SQL DATA SQL SECURITY DEFINER
BEGIN
 DECLARE v_start DATE;
 DECLARE v_price DECIMAL(12,2);
 SET v_start=DATE_SUB(p_date,INTERVAL DAYOFMONTH(p_date)-1 DAY);
 SELECT p.price * IF(EXISTS(
  SELECT 1 FROM order_line l JOIN stock_item s USING(item_id)
  JOIN sales_order o USING(order_id)
  WHERE s.product_id=p.product_id
   AND o.ordered_at>=DATE_SUB(v_start,INTERVAL 1 MONTH)
   AND o.ordered_at<v_start
 ),1,0.75) INTO v_price FROM product p WHERE p.product_id=p_product;
 RETURN ROUND(v_price,2);
END$$
DELIMITER ;
-- === Роль пользователя и роль подключения
DROP FUNCTION IF EXISTS pp_role;
DELIMITER $$
CREATE FUNCTION pp_role(p_actor BIGINT)
RETURNS VARCHAR(20) READS SQL DATA SQL SECURITY DEFINER
BEGIN
 DECLARE v_role VARCHAR(20);
 DECLARE v_account VARCHAR(80);
 SELECT CASE r.name WHEN 'Администратор' THEN 'admin'
  WHEN 'Менеджер' THEN 'manager' ELSE 'client' END
 INTO v_role FROM customer c JOIN app_role r USING(role_id)
 WHERE c.customer_id=p_actor;
 SET v_account=SUBSTRING_INDEX(USER(),'@',1);
 IF v_role IS NULL OR (v_account<>'root' AND
  (v_account NOT LIKE 'pp11\_%' OR
   SUBSTRING_INDEX(v_account,'_',-1)<>v_role)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 RETURN v_role;
END$$
DELIMITER ;

-- === Каталог из БД с единой ценой и остатком
DROP PROCEDURE IF EXISTS pp_catalog;
DELIMITER $$
CREATE PROCEDURE pp_catalog(IN p_date DATE) SQL SECURITY DEFINER
BEGIN
 SELECT p.product_id,p.name,c.category_id,c.name AS category,
  m.name AS manufacturer,p.composition,p.description,p.image_path,
  p.price,pp_price(p.product_id,p_date) AS final_price,
  COALESCE(SUM(s.available),0) AS available
 FROM product p JOIN subcategory sc USING(subcategory_id)
 JOIN category c USING(category_id) JOIN manufacturer m USING(manufacturer_id)
 LEFT JOIN stock_item s USING(product_id)
 GROUP BY p.product_id,p.name,c.category_id,c.name,m.name,p.composition,
  p.description,p.image_path,p.price ORDER BY p.product_id;
END$$
DELIMITER ;
-- === Вход по логину и размерный ряд
DROP PROCEDURE IF EXISTS pp_login;
DROP PROCEDURE IF EXISTS pp_sizes;
DELIMITER $$
CREATE PROCEDURE pp_login(IN p_login VARCHAR(80)) SQL SECURITY DEFINER
BEGIN
 SELECT c.customer_id,CONCAT_WS(' ',c.last_name,c.first_name,
  NULLIF(c.patronymic,'')) AS fio,
  CASE r.name WHEN 'Администратор' THEN 'admin'
   WHEN 'Менеджер' THEN 'manager' ELSE 'client' END AS role_name
 FROM customer c JOIN app_role r USING(role_id) WHERE c.login=p_login;
END$$
CREATE PROCEDURE pp_sizes(IN p_product BIGINT) SQL SECURITY DEFINER
BEGIN
 SELECT s.item_id,z.label,s.available FROM stock_item s JOIN size z USING(size_id)
 WHERE s.product_id=p_product ORDER BY z.size_id;
END$$
DELIMITER ;
-- === Данные для работы сотрудников
DROP PROCEDURE IF EXISTS pp_customers;
DROP PROCEDURE IF EXISTS pp_orders;
DROP PROCEDURE IF EXISTS pp_lines;
DELIMITER $$
CREATE PROCEDURE pp_customers(IN p_actor BIGINT) SQL SECURITY DEFINER
BEGIN
 IF pp_role(p_actor) NOT IN ('manager','admin') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 SELECT customer_id,CONCAT_WS(' ',last_name,first_name,NULLIF(patronymic,'')) AS fio
 FROM customer ORDER BY last_name,first_name,customer_id;
END$$
CREATE PROCEDURE pp_orders(IN p_actor BIGINT) SQL SECURITY DEFINER
BEGIN
 IF pp_role(p_actor) NOT IN ('manager','admin') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 SELECT o.order_id,o.ordered_at,
  CONCAT_WS(' ',c.last_name,c.first_name,NULLIF(c.patronymic,'')) AS fio,
  COALESCE(SUM(l.quantity*l.unit_price),0) AS total
 FROM sales_order o JOIN customer c USING(customer_id)
 LEFT JOIN order_line l USING(order_id)
 GROUP BY o.order_id,o.ordered_at,c.last_name,c.first_name,c.patronymic
 ORDER BY o.ordered_at DESC,o.order_id DESC;
END$$
CREATE PROCEDURE pp_lines(IN p_actor BIGINT,IN p_order BIGINT) SQL SECURITY DEFINER
BEGIN
 IF pp_role(p_actor) NOT IN ('manager','admin') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 SELECT l.item_id,CONCAT(p.name,' / ',m.name,' / ',z.label) AS position,
  l.quantity,l.unit_price,l.quantity*l.unit_price AS total
 FROM order_line l JOIN stock_item s USING(item_id) JOIN product p USING(product_id)
 JOIN manufacturer m USING(manufacturer_id) JOIN size z USING(size_id)
 WHERE l.order_id=p_order ORDER BY l.item_id;
END$$
DELIMITER ;
