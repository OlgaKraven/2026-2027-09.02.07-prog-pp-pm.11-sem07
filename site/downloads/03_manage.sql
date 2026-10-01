-- === Отмена заказа с возвратом всех позиций
DROP PROCEDURE IF EXISTS pp_delete_order;
DELIMITER $$
CREATE PROCEDURE pp_delete_order(IN p_actor BIGINT,IN p_order BIGINT)
SQL SECURITY DEFINER
BEGIN
 DECLARE v_id BIGINT;
 DECLARE v_item BIGINT;
 DECLARE v_qty INT;
 DECLARE v_done INT DEFAULT 0;
 DECLARE cur CURSOR FOR SELECT item_id,quantity FROM order_line
  WHERE order_id=p_order ORDER BY item_id;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=1;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
 IF pp_role(p_actor) NOT IN ('manager','admin') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 START TRANSACTION;
 SET v_id=NULL;
 SELECT order_id INTO v_id FROM sales_order WHERE order_id=p_order FOR UPDATE;
 IF v_id IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ORDER_NOT_FOUND';
 END IF;
 SET v_done=0;
 OPEN cur;
 read_loop: LOOP
  FETCH cur INTO v_item,v_qty;
  IF v_done=1 THEN LEAVE read_loop; END IF;
  UPDATE stock_item SET available=available+v_qty WHERE item_id=v_item;
 END LOOP;
 CLOSE cur;
 DELETE FROM sales_order WHERE order_id=p_order;
 COMMIT;
END$$
DELIMITER ;
-- === Удаление строки администратором
DROP PROCEDURE IF EXISTS pp_delete_line;
DELIMITER $$
CREATE PROCEDURE pp_delete_line(IN p_actor BIGINT,IN p_order BIGINT,IN p_item BIGINT)
SQL SECURITY DEFINER
BEGIN
 DECLARE v_id BIGINT;
 DECLARE v_qty INT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
 IF pp_role(p_actor)<>'admin' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 START TRANSACTION;
 SET v_id=(SELECT order_id FROM sales_order WHERE order_id=p_order FOR UPDATE);
 SET v_qty=(SELECT quantity FROM order_line
  WHERE order_id=p_order AND item_id=p_item FOR UPDATE);
 IF v_id IS NULL OR v_qty IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='LINE_NOT_FOUND';
 END IF;
 UPDATE stock_item SET available=available+v_qty WHERE item_id=p_item;
 DELETE FROM order_line WHERE order_id=p_order AND item_id=p_item;
 IF NOT EXISTS(SELECT 1 FROM order_line WHERE order_id=p_order) THEN
  DELETE FROM sales_order WHERE order_id=p_order;
 END IF;
 COMMIT;
END$$
DELIMITER ;
-- === Изменение даты без пересчёта исторических цен
DROP PROCEDURE IF EXISTS pp_change_date;
DELIMITER $$
CREATE PROCEDURE pp_change_date(IN p_actor BIGINT,IN p_order BIGINT,IN p_date DATETIME)
SQL SECURITY DEFINER
BEGIN
 IF pp_role(p_actor)<>'admin' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ROLE_DENIED';
 END IF;
 IF p_date IS NULL OR p_date>NOW() THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='INVALID_DATE';
 END IF;
 UPDATE sales_order SET ordered_at=p_date WHERE order_id=p_order;
 IF ROW_COUNT()=0 AND NOT EXISTS(SELECT 1 FROM sales_order WHERE order_id=p_order) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ORDER_NOT_FOUND';
 END IF;
END$$
DELIMITER ;
