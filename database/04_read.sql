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
