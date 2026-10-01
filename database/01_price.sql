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
