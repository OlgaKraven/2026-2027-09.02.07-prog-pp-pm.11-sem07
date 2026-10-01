
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `app_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `app_role` (
  `role_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `app_role` WRITE;
/*!40000 ALTER TABLE `app_role` DISABLE KEYS */;
INSERT INTO `app_role` VALUES (1,'Клиент');
/*!40000 ALTER TABLE `app_role` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `catalog`;
/*!50001 DROP VIEW IF EXISTS `catalog`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `catalog` AS SELECT
 1 AS `item_id`,
  1 AS `name`,
  1 AS `category`,
  1 AS `subcategory`,
  1 AS `manufacturer`,
  1 AS `size`,
  1 AS `available`,
  1 AS `price`,
  1 AS `image_path` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `category` (
  `category_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL CHECK (trim(`name`) <> ''),
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
INSERT INTO `category` VALUES (1,'Сумки'),(2,'Чехлы');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `customer` (
  `customer_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `login` varchar(80) NOT NULL,
  `last_name` varchar(80) NOT NULL,
  `first_name` varchar(80) NOT NULL,
  `patronymic` varchar(80) NOT NULL DEFAULT '',
  `role_id` bigint(20) NOT NULL,
  PRIMARY KEY (`customer_id`),
  UNIQUE KEY `login` (`login`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `customer_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `app_role` (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `customer` WRITE;
/*!40000 ALTER TABLE `customer` DISABLE KEYS */;
INSERT INTO `customer` VALUES (1,'buyer','Петрова','Анна','Сергеевна',1),(2,'client','Иванов','Иван','Иванович',1);
/*!40000 ALTER TABLE `customer` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `manufacturer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `manufacturer` (
  `manufacturer_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  PRIMARY KEY (`manufacturer_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `manufacturer` WRITE;
/*!40000 ALTER TABLE `manufacturer` DISABLE KEYS */;
INSERT INTO `manufacturer` VALUES (1,'Учебная фабрика');
/*!40000 ALTER TABLE `manufacturer` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `order_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_line` (
  `order_id` bigint(20) NOT NULL,
  `item_id` bigint(20) NOT NULL,
  `quantity` int(11) NOT NULL CHECK (`quantity` > 0),
  `unit_price` decimal(12,2) NOT NULL CHECK (`unit_price` > 0),
  PRIMARY KEY (`order_id`,`item_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `order_line_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `sales_order` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `order_line_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `stock_item` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `order_line` WRITE;
/*!40000 ALTER TABLE `order_line` DISABLE KEYS */;
INSERT INTO `order_line` VALUES (1,1,1,125.00);
/*!40000 ALTER TABLE `order_line` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `order_totals`;
/*!50001 DROP VIEW IF EXISTS `order_totals`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `order_totals` AS SELECT
 1 AS `order_id`,
  1 AS `ordered_at`,
  1 AS `customer`,
  1 AS `total` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product` (
  `product_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `subcategory_id` bigint(20) NOT NULL,
  `manufacturer_id` bigint(20) NOT NULL,
  `name` varchar(200) NOT NULL,
  `image_path` varchar(255) NOT NULL DEFAULT '',
  `description` text NOT NULL,
  `composition` text NOT NULL,
  `price` decimal(12,2) NOT NULL CHECK (`price` > 0),
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `name` (`name`,`manufacturer_id`),
  KEY `subcategory_id` (`subcategory_id`),
  KEY `manufacturer_id` (`manufacturer_id`),
  CONSTRAINT `product_ibfk_1` FOREIGN KEY (`subcategory_id`) REFERENCES `subcategory` (`subcategory_id`),
  CONSTRAINT `product_ibfk_2` FOREIGN KEY (`manufacturer_id`) REFERENCES `manufacturer` (`manufacturer_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `product` WRITE;
/*!40000 ALTER TABLE `product` DISABLE KEYS */;
INSERT INTO `product` VALUES (1,2,1,'Чехол ноутбука','','Водостойкий материал, модель для ежедневного использования.','Текстиль и полимер',125.00),(2,1,1,'Чехол ноутбука — облегчённая модель','','Водостойкий материал, модель для ежедневного использования.','Текстиль и полимер',34.00),(3,2,1,'Чехол ноутбука — резервная модель','','Базовая модель для регулярного использования.','Текстиль и полимер',75.00),(4,2,1,'Чехол планшета','','Базовая модель для регулярного использования.','Текстиль и полимер',45.00),(5,1,1,'Чехол планшета — усиленная модель','','Базовая модель для регулярного использования.','Текстиль и полимер',245.00);
/*!40000 ALTER TABLE `product` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `sales_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sales_order` (
  `order_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `customer_id` bigint(20) NOT NULL,
  `ordered_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`order_id`),
  KEY `ix_order_customer_date` (`customer_id`,`ordered_at`),
  CONSTRAINT `sales_order_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `sales_order` WRITE;
/*!40000 ALTER TABLE `sales_order` DISABLE KEYS */;
INSERT INTO `sales_order` VALUES (1,2,'2026-09-01 10:00:00');
/*!40000 ALTER TABLE `sales_order` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `size`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `size` (
  `size_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `label` varchar(30) NOT NULL,
  PRIMARY KEY (`size_id`),
  UNIQUE KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `size` WRITE;
/*!40000 ALTER TABLE `size` DISABLE KEYS */;
INSERT INTO `size` VALUES (1,'13 дюймов'),(2,'15 дюймов');
/*!40000 ALTER TABLE `size` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stg_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stg_orders` (
  `order_id` text DEFAULT NULL,
  `ordered_at` text DEFAULT NULL,
  `full_name` text DEFAULT NULL,
  `category` text DEFAULT NULL,
  `name` text DEFAULT NULL,
  `manufacturer` text DEFAULT NULL,
  `size` text DEFAULT NULL,
  `quantity` text DEFAULT NULL,
  `unit_price` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stg_orders` WRITE;
/*!40000 ALTER TABLE `stg_orders` DISABLE KEYS */;
INSERT INTO `stg_orders` VALUES ('1','2026-09-01 10:00:00','Иванов Иван Иванович','Чехлы','Чехол ноутбука','Учебная фабрика','13 дюймов','1','125');
/*!40000 ALTER TABLE `stg_orders` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stg_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stg_products` (
  `category` text DEFAULT NULL,
  `subcategory` text DEFAULT NULL,
  `image_path` text DEFAULT NULL,
  `name` text DEFAULT NULL,
  `manufacturer` text DEFAULT NULL,
  `description` text DEFAULT NULL,
  `composition` text DEFAULT NULL,
  `price` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stg_products` WRITE;
/*!40000 ALTER TABLE `stg_products` DISABLE KEYS */;
INSERT INTO `stg_products` VALUES ('Чехлы','Основной ассортимент','','Чехол ноутбука','Учебная фабрика','Водостойкий материал, модель для ежедневного использования.','Текстиль и полимер','125'),('Чехлы','Основной ассортимент','','Чехол планшета','Учебная фабрика','Базовая модель для регулярного использования.','Текстиль и полимер','45'),('Сумки','Основной ассортимент','','Чехол ноутбука — облегчённая модель','Учебная фабрика','Водостойкий материал, модель для ежедневного использования.','Текстиль и полимер','34'),('Сумки','Основной ассортимент','','Чехол планшета — усиленная модель','Учебная фабрика','Базовая модель для регулярного использования.','Текстиль и полимер','245'),('Чехлы','Основной ассортимент','','Чехол ноутбука — резервная модель','Учебная фабрика','Базовая модель для регулярного использования.','Текстиль и полимер','75');
/*!40000 ALTER TABLE `stg_products` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stg_sizes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stg_sizes` (
  `label` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stg_sizes` WRITE;
/*!40000 ALTER TABLE `stg_sizes` DISABLE KEYS */;
INSERT INTO `stg_sizes` VALUES ('13 дюймов'),('15 дюймов');
/*!40000 ALTER TABLE `stg_sizes` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stg_stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stg_stock` (
  `name` text DEFAULT NULL,
  `manufacturer` text DEFAULT NULL,
  `size` text DEFAULT NULL,
  `available` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stg_stock` WRITE;
/*!40000 ALTER TABLE `stg_stock` DISABLE KEYS */;
INSERT INTO `stg_stock` VALUES ('Чехол ноутбука','Учебная фабрика','13 дюймов','5'),('Чехол ноутбука','Учебная фабрика','15 дюймов','3'),('Чехол планшета','Учебная фабрика','13 дюймов','2'),('Чехол планшета','Учебная фабрика','15 дюймов','1'),('Чехол ноутбука — облегчённая модель','Учебная фабрика','13 дюймов','2'),('Чехол ноутбука — облегчённая модель','Учебная фабрика','15 дюймов','1'),('Чехол планшета — усиленная модель','Учебная фабрика','13 дюймов','2'),('Чехол планшета — усиленная модель','Учебная фабрика','15 дюймов','1'),('Чехол ноутбука — резервная модель','Учебная фабрика','13 дюймов','2'),('Чехол ноутбука — резервная модель','Учебная фабрика','15 дюймов','0');
/*!40000 ALTER TABLE `stg_stock` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stg_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stg_users` (
  `last_name` text DEFAULT NULL,
  `first_name` text DEFAULT NULL,
  `patronymic` text DEFAULT NULL,
  `login` text DEFAULT NULL,
  `role` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stg_users` WRITE;
/*!40000 ALTER TABLE `stg_users` DISABLE KEYS */;
INSERT INTO `stg_users` VALUES ('Иванов','Иван','Иванович','client','Клиент'),('Петрова','Анна','Сергеевна','buyer','Клиент');
/*!40000 ALTER TABLE `stg_users` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stock_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stock_item` (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) NOT NULL,
  `size_id` bigint(20) NOT NULL,
  `available` int(11) NOT NULL CHECK (`available` >= 0),
  PRIMARY KEY (`item_id`),
  UNIQUE KEY `product_id` (`product_id`,`size_id`),
  KEY `size_id` (`size_id`),
  CONSTRAINT `stock_item_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`),
  CONSTRAINT `stock_item_ibfk_2` FOREIGN KEY (`size_id`) REFERENCES `size` (`size_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stock_item` WRITE;
/*!40000 ALTER TABLE `stock_item` DISABLE KEYS */;
INSERT INTO `stock_item` VALUES (1,1,1,5),(2,1,2,3),(3,2,1,2),(4,2,2,1),(5,3,1,2),(6,3,2,0),(7,4,1,2),(8,4,2,1),(9,5,1,2),(10,5,2,1);
/*!40000 ALTER TABLE `stock_item` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `subcategory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subcategory` (
  `subcategory_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `category_id` bigint(20) NOT NULL,
  `name` varchar(120) NOT NULL,
  PRIMARY KEY (`subcategory_id`),
  UNIQUE KEY `category_id` (`category_id`,`name`),
  CONSTRAINT `subcategory_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `subcategory` WRITE;
/*!40000 ALTER TABLE `subcategory` DISABLE KEYS */;
INSERT INTO `subcategory` VALUES (1,1,'Основной ассортимент'),(2,2,'Основной ассортимент');
/*!40000 ALTER TABLE `subcategory` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `place_order` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `place_order`(IN p_customer BIGINT,IN p_lines LONGTEXT)
BEGIN
 DECLARE v_order BIGINT;
 DECLARE v_item BIGINT;
 DECLARE v_quantity INT;
 DECLARE v_available INT;
 DECLARE v_price DECIMAL(12,2);
 DECLARE v_index INT DEFAULT 0;
 DECLARE v_count INT;
 DECLARE v_done INT DEFAULT 0;
 DECLARE v_id_text TEXT;
 DECLARE v_qty_text TEXT;
 DECLARE cur CURSOR FOR SELECT item_id,quantity FROM request_lines ORDER BY item_id;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=1;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  ROLLBACK;
  DROP TEMPORARY TABLE IF EXISTS request_lines;
  RESIGNAL;
 END;
 
 IF p_lines IS NULL OR JSON_VALID(p_lines)=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Invalid JSON';
 END IF;
 IF JSON_TYPE(p_lines)<>'ARRAY' OR JSON_LENGTH(p_lines)=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Nonempty array required';
 END IF;
 DROP TEMPORARY TABLE IF EXISTS request_lines;
 CREATE TEMPORARY TABLE request_lines (
  item_id BIGINT PRIMARY KEY,quantity INT NOT NULL
 ) ENGINE=InnoDB;
 SET v_count=JSON_LENGTH(p_lines);
 WHILE v_index<v_count DO
  SET v_id_text=JSON_UNQUOTE(JSON_EXTRACT(p_lines,CONCAT('$[',v_index,'].item_id')));
  SET v_qty_text=JSON_UNQUOTE(JSON_EXTRACT(p_lines,CONCAT('$[',v_index,'].quantity')));
  IF v_id_text IS NULL OR v_qty_text IS NULL
   OR v_id_text NOT REGEXP '^[1-9][0-9]*$'
   OR v_qty_text NOT REGEXP '^[1-9][0-9]*$' THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Positive integer item and quantity required';
  END IF;
  INSERT INTO request_lines VALUES(CAST(v_id_text AS UNSIGNED),CAST(v_qty_text AS UNSIGNED))
  ON DUPLICATE KEY UPDATE quantity=quantity+VALUES(quantity);
  SET v_index=v_index+1;
 END WHILE;
 
 START TRANSACTION;
 INSERT INTO sales_order(customer_id) VALUES(p_customer);
 SET v_order=LAST_INSERT_ID();
 OPEN cur;
 read_loop: LOOP
  FETCH cur INTO v_item,v_quantity;
  IF v_done=1 THEN LEAVE read_loop; END IF;
  SET v_available=NULL;
  SELECT s.available,p.price INTO v_available,v_price
  FROM stock_item s JOIN product p USING(product_id)
  WHERE s.item_id=v_item FOR UPDATE;
  IF v_available IS NULL THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Unknown item';
  END IF;
  IF v_available<v_quantity THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Not enough stock';
  END IF;
  
  INSERT INTO order_line(order_id,item_id,quantity,unit_price)
  VALUES(v_order,v_item,v_quantity,v_price);
  UPDATE stock_item SET available=available-v_quantity WHERE item_id=v_item;
 END LOOP;
 CLOSE cur;
 COMMIT;
 DROP TEMPORARY TABLE request_lines;
 SELECT v_order AS created_order;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50001 DROP VIEW IF EXISTS `catalog`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `catalog` AS select `i`.`item_id` AS `item_id`,`p`.`name` AS `name`,`c`.`name` AS `category`,`sc`.`name` AS `subcategory`,`m`.`name` AS `manufacturer`,`z`.`label` AS `size`,`i`.`available` AS `available`,`p`.`price` AS `price`,`p`.`image_path` AS `image_path` from (((((`stock_item` `i` join `product` `p` on(`i`.`product_id` = `p`.`product_id`)) join `subcategory` `sc` on(`p`.`subcategory_id` = `sc`.`subcategory_id`)) join `category` `c` on(`sc`.`category_id` = `c`.`category_id`)) join `manufacturer` `m` on(`p`.`manufacturer_id` = `m`.`manufacturer_id`)) join `size` `z` on(`i`.`size_id` = `z`.`size_id`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `order_totals`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `order_totals` AS select `o`.`order_id` AS `order_id`,`o`.`ordered_at` AS `ordered_at`,concat_ws(' ',`c`.`last_name`,`c`.`first_name`,nullif(`c`.`patronymic`,'')) AS `customer`,cast(sum(`l`.`quantity` * `l`.`unit_price`) as decimal(14,2)) AS `total` from ((`sales_order` `o` join `customer` `c` on(`o`.`customer_id` = `c`.`customer_id`)) join `order_line` `l` on(`o`.`order_id` = `l`.`order_id`)) group by `o`.`order_id`,`o`.`ordered_at`,`c`.`customer_id`,`c`.`last_name`,`c`.`first_name`,`c`.`patronymic` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

