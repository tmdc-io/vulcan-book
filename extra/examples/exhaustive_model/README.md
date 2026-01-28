# B2B SaaS Example - Split Docker Compose Setup

This project uses split Docker Compose files for better service management and scalability. Services are organized into separate compose files that share a common external Docker network.

## Setup

You can use `make` commands for convenience, or run the docker compose commands directly.


make setup 


make vulcan-up


alias vulcan="docker run -it --network=vulcan  --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev vulcan"
 
vulcan plan 



make vulcan-down 

make all-down

vulcan transpile --format sql "select measure(total_order_lines) from orders"

vulcan create_test ANALYTICS.ORDERS --query DEMO.RAW_DATA.ORDERS "select ORDER_ID ,ORDER_DATE ,CUSTOMER_ID ,PRODUCT_ID ,QUANTITY ,UNIT_PRICE ,DISCOUNT ,TAX ,SHIPPING_COST ,TOTAL_AMOUNT FROM DEMO.RAW_DATA.ORDERS
WHERE ORDER_DATE  BETWEEN '2025-01-01' and '2025-01-15'"


