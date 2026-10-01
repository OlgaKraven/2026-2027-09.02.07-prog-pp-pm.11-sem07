-- === Контракт заказа и обработчик отката
DROP PROCEDURE IF EXISTS pp_checkout;
DELIMITER $$
CREATE PROCEDURE pp_checkout(IN p_actor BIGINT,IN p_customer BIGINT,
 IN p_lines LONGTEXT,IN p_key CHAR(36)) SQL SECURITY DEFINER
proc: BEGIN
 DECLARE v_role VARCHAR(20);
 DECLARE v_order BIGINT;
 DECLARE v_creator BIGINT;
 DECLARE v_item BIGINT;
 DECLARE v_product BIGINT;
 DECLARE v_quantity INT;
 DECLARE v_available INT;
 DECLARE v_price DECIMAL(12,2);
 DECLARE v_date DATETIME;
 DECLARE v_index INT DEFAULT 0;
 DECLARE v_done INT DEFAULT 0;
 DECLARE v_id_text TEXT;
 DECLARE v_qty_text TEXT;
 DECLARE cur CURSOR FOR SELECT item_id,quantity FROM pp_request ORDER BY item_id;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=1;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  ROLLBACK;
  DROP TEMPORARY TABLE IF EXISTS pp_request;
  RESIGNAL;
 END;
 -- === Роль, повтор запроса и проверка входа
 SET v_role=pp_role(p_actor);
 IF v_role='client' AND p_customer<>p_actor THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 IF p_key IS NULL OR p_key NOT REGEXP
  '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='INVALID_REQUEST';
 END IF;
 SET v_order=(SELECT order_id FROM sales_order WHERE request_key=p_key);
 IF v_order IS NOT NULL THEN
  SELECT created_by INTO v_creator FROM sales_order WHERE order_id=v_order;
  IF v_creator<>p_actor THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
  END IF;
  SELECT v_order AS created_order;
  LEAVE proc;
 END IF;
 IF p_lines IS NULL OR JSON_VALID(p_lines)=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='INVALID_LINES';
 END IF;
 IF JSON_TYPE(p_lines)<>'ARRAY' OR JSON_LENGTH(p_lines)=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='EMPTY_ORDER';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM customer WHERE customer_id=p_customer) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='UNKNOWN_CUSTOMER';
 END IF;
 DROP TEMPORARY TABLE IF EXISTS pp_request;
 CREATE TEMPORARY TABLE pp_request(item_id BIGINT PRIMARY KEY,
  quantity INT NOT NULL) ENGINE=InnoDB;
 WHILE v_index<JSON_LENGTH(p_lines) DO
  SET v_id_text=JSON_UNQUOTE(JSON_EXTRACT(p_lines,CONCAT('$[',v_index,'].item_id')));
  SET v_qty_text=JSON_UNQUOTE(JSON_EXTRACT(p_lines,CONCAT('$[',v_index,'].quantity')));
  IF v_id_text IS NULL OR v_qty_text IS NULL
   OR v_id_text NOT REGEXP '^[1-9][0-9]{0,9}$'
   OR v_qty_text NOT REGEXP '^[1-9][0-9]{0,5}$' THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='INVALID_QUANTITY';
  END IF;
  INSERT INTO pp_request VALUES(CAST(v_id_text AS UNSIGNED),CAST(v_qty_text AS UNSIGNED))
  ON DUPLICATE KEY UPDATE quantity=quantity+VALUES(quantity);
  SET v_index=v_index+1;
 END WHILE;
 -- === Сохранение цены и остатков одной транзакцией
 SET v_date=NOW();
 START TRANSACTION;
 INSERT INTO sales_order(customer_id,ordered_at,request_key,created_by)
 VALUES(p_customer,v_date,p_key,p_actor);
 SET v_order=LAST_INSERT_ID();
 SET v_done=0;
 OPEN cur;
 read_loop: LOOP
  FETCH cur INTO v_item,v_quantity;
  IF v_done=1 THEN LEAVE read_loop; END IF;
  SET v_available=NULL;
  SELECT available,product_id INTO v_available,v_product
  FROM stock_item WHERE item_id=v_item FOR UPDATE;
  IF v_available IS NULL THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='UNKNOWN_ITEM';
  END IF;
  IF v_available<v_quantity THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='NOT_ENOUGH_STOCK';
  END IF;
  SET v_price=pp_price(v_product,DATE(v_date));
  INSERT INTO order_line(order_id,item_id,quantity,unit_price)
  VALUES(v_order,v_item,v_quantity,v_price);
  UPDATE stock_item SET available=available-v_quantity WHERE item_id=v_item;
 END LOOP;
 CLOSE cur;
 COMMIT;
 DROP TEMPORARY TABLE pp_request;
 SELECT v_order AS created_order;
END$$
DELIMITER ;
