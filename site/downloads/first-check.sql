SET @actor=(SELECT customer_id FROM customer WHERE login='pp_client');
SET @item=(SELECT item_id FROM stock_item WHERE available>0 ORDER BY item_id LIMIT 1);
SET @before=(SELECT available FROM stock_item WHERE item_id=@item);
SET @key=UUID();
SELECT @actor AS customer_id,@item AS item_id,@before AS stock_before;
CALL pp_checkout(@actor,@actor,JSON_ARRAY(JSON_OBJECT('item_id',@item,'quantity',1)),@key);
SET @order=(SELECT order_id FROM sales_order WHERE request_key=@key);
SELECT o.order_id,o.customer_id,l.item_id,l.quantity,l.unit_price,l.quantity*l.unit_price AS total
FROM sales_order o JOIN order_line l USING(order_id) WHERE o.order_id=@order;
SELECT @before AS before_value,available AS after_value FROM stock_item WHERE item_id=@item;
