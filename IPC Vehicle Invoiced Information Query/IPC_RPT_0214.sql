/* Formatted on 26/7/2017 8:24:51 AM (QP5 v5.163.1008.3004) */
SELECT *
  FROM (  SELECT hp.party_name customer_name,
                 hcaa.account_name,
                 hcaa.account_number,
                 hcsua.location,
                 regexp_replace(hl.address1,'DEALERS-PARTS|DEALERS-VEHICLE|DEALERS-FLEET','') || ' ' || hl.address2 || ' ' || hl.address3
                 address,
                 hcsua.tax_reference,
                 rcta.trx_number invoice_no,
                 rcta.trx_date invoice_date,
                 rtt.name term,
                 msn.attribute1 csr,
                 msn.attribute12 csr_or,
                 CASE 
                        WHEN rcta.attribute5 IS NOT NULL
                        THEN TO_CHAR(TO_DATE(rcta.attribute5,'YYYY/MM/DD HH24:MI:SS'),'MM/DD/YYYY')
                        ELSE NULL
                 end pull_out_date,
                CASE
                    WHEN REGEXP_LIKE (msn.attribute5,
                    '^[0-9]{2}-\w{3}-[0-9]{2}$' --     DD-MON-YY
                    )
                    THEN TO_CHAR (msn.attribute5, 'MM/DD/YYYY')
                    WHEN REGEXP_LIKE (msn.attribute5,
                    '^[0-9]{2}-\w{3}-[0-9]{4}$'  -- DD-MON-YYYY
                    )
                    THEN TO_CHAR (msn.attribute5, 'MM/DD/YYYY')
                    WHEN REGEXP_LIKE (msn.attribute5,
                    '^[0-9]{4}/[0-9]{2}/[0-9]{2}' -- YYYY/MM/DD
                    )
                    THEN TO_CHAR (TO_DATE (msn.attribute5,
                    'YYYY/MM/DD HH24:MI:SS'
                    ),
                    'MM/DD/YYYY'
                    )
                    WHEN REGEXP_LIKE (msn.attribute5,
                    '^[0-9]{2}/[0-9]{2}/[0-9]{4}' -- MM/DD/YYYY
                    )
                    THEN TO_CHAR (TO_DATE (msn.attribute5,
                    'MM/DD/YYYY'
                    ),
                    'MM/DD/YYYY'
                    )
                    ELSE TO_CHAR(to_Date(msn.attribute5, 'MM/DD/YYYY'),'MM/DD/YYYY')
                END buyoff_date,
                 MAX (rctla.quantity_invoiced) quantity,
                 SUM (
                    CASE
                       WHEN rctla.interface_line_attribute11 = 0
                       THEN
                          rctla.line_recoverable
                       ELSE
                          0
                    END)
                    gross,
                 CASE
                    WHEN rcta.cust_trx_type_id = 1002
                    THEN
                       CASE
                          WHEN SUM (
                                  DECODE (rctla.interface_line_attribute11,
                                          '0', 0,
                                          rctla.line_recoverable)) > 0
                          THEN
                             0
                          ELSE
                             SUM (
                                DECODE (rctla.interface_line_attribute11,
                                        '0', 0,
                                        rctla.line_recoverable))
                       END
                    WHEN rcta.cust_trx_type_id IN (3081, 6081)
                    THEN
                       CASE
                          WHEN SUM (
                                  DECODE (rctla.interface_line_attribute11,
                                          '0', 0,
                                          rctla.line_recoverable)) < 0
                          THEN
                             0
                          ELSE
                             SUM (
                                DECODE (rctla.interface_line_attribute11,
                                        '0', 0,
                                        rctla.line_recoverable))
                       END
                 END
                    discount,
                 SUM (rctla.tax_recoverable) tax,
                 rcta.interface_header_attribute1 so_num,
                 rcta.purchase_order,
                 wnd.delivery_id dr_num,
                 msib.description model,
                 msn.lot_number,
                 msn.attribute2 chassis_number,
                 msn.attribute3 engine_number,
                 msib.attribute8 body_color,
                 msib.attribute17 fuel_type,
                 msn.attribute6 key_no,
                 msib.attribute13 tire_brand,
                 msib.attribute12 battery,
                 msn.serial_number cs_no,
                 msib.attribute21 year_model,
                 we.wip_entity_name job_order_no,
                 mmt.trx_source_line_id ,
                  msn.last_transaction_id,
                   mmt.transaction_id
            --            credit_invoices.trx_number credit_invoice
            FROM -- INVOICE
                 ra_customer_trx_all rcta
                 INNER JOIN ra_customer_trx_lines_all rctla
                    ON rctla.customer_trx_id = rcta.customer_trx_id
                 INNER JOIN ra_cust_trx_types_all rctta
                    ON rctta.cust_trx_type_id = rcta.cust_trx_type_id
             
                 -- CUSTOMER DATA
                 INNER JOIN hz_cust_accounts_all hcaa
                    ON hcaa.cust_account_id = rcta.bill_to_customer_id
                 INNER JOIN hz_cust_site_uses_all hcsua
                    ON     hcsua.site_use_id = rcta.bill_to_site_use_id
                       AND hcsua.status = 'A'
                       AND hcsua.site_use_code = 'BILL_TO'
                 INNER JOIN hz_parties hp
                    ON hp.party_id = hcaa.party_id
                 INNER JOIN hz_cust_acct_sites_all hcasa
                    ON hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
                 INNER JOIN hz_party_sites hps
                    ON hps.party_site_id = hcasa.party_site_id
                 INNER JOIN hz_locations hl
                    ON hl.location_id = hps.location_id
                 -- TERMS
                 LEFT JOIN ra_terms_tl rtt
                    ON rtt.term_id = rcta.term_id
                 -- SALES ORDER
                 LEFT JOIN oe_order_headers_all ooha
                    ON TO_CHAR (rcta.interface_header_attribute1) =
                          TO_CHAR (ooha.order_number)
                 INNER JOIN oe_order_lines_all oola
                    ON oola.header_id = ooha.header_id
                       AND oola.line_number = rctla.sales_order_line
                 LEFT JOIN wsh_delivery_details wdd
                    ON oola.line_id = wdd.source_line_id
                 LEFT JOIN wsh_delivery_assignments wda
                    ON wdd.delivery_detail_id = wda.delivery_detail_id
                 LEFT JOIN wsh_new_deliveries wnd
                    ON wda.delivery_id = wnd.delivery_id
                 -- MATERIAL TRANSACTIONS
                 LEFT JOIN (SELECT mmts.*
                              FROM    mtl_material_transactions mmts
                                   LEFT JOIN
                                      mtl_transaction_types mtt
                                   ON mmts.transaction_type_id =
                                         mtt.transaction_type_id
                             WHERE 1 = 1
                                   AND mtt.transaction_type_name IN
                                          ('Sales order issue',
                                           'Sales Order Pick')) mmt
                    ON mmt.trx_source_line_id = oola.line_id
                      AND mmt.trx_source_delivery_id = wnd.delivery_id
                 LEFT JOIN mtl_serial_numbers msn
                    ON msn.last_transaction_id = mmt.transaction_id
                 LEFT JOIN mtl_system_items_b msib
                    ON msn.inventory_item_id = msib.inventory_item_id
                     AND msib.organization_id = msn.current_organization_id
                LEFT JOIN wip_entities we
                    ON msn.original_wip_entity_id = we.wip_entity_id
           WHERE 1 = 1 -- filter
                 
        GROUP BY hp.party_name,
                 hcaa.account_name,
                 hcaa.account_number,
                 hcsua.location,
                 hl.address1,hl.address2,hl.address3,
                 hcsua.tax_reference,
                 rcta.trx_number,
                 rcta.trx_date,
                 rtt.name,
                 msn.attribute1,
                 rcta.attribute5,
                 rcta.attribute3,
                 rcta.interface_header_attribute1,
                 rcta.purchase_order,
                 wnd.delivery_id,
                 msib.description,
                 msn.lot_number,
                 msn.attribute2,
                 msn.attribute3,
                 msn.attribute12,
                 msib.attribute8,
                 msib.attribute17,
                 msn.attribute6,
                 msib.attribute13,
                 msib.attribute12,
                 msn.serial_number,
                 msib.attribute21,
                 msn.attribute5,
                rcta.cust_trx_type_id,
                mmt.trx_source_line_id,
                msn.last_transaction_id,
                mmt.transaction_id,
                we.wip_entity_name
       )
 WHERE 1 = 1 
               AND gross <> 0
               AND invoice_no like '403%'
               
               and cs_no = 'CS6287';
               AND invoice_date Between 
                       TO_DATE(:P_INVOICED_START,'YYYY/MM/DD HH24:MI:SS') AND 
                       TO_DATE(:P_INVOICED_END,'YYYY/MM/DD HH24:MI:SS');


select original_wip_entity_id
from mtl_serial_numbers
where serial_number in ('CR4959',
'CO7994',
'CS0413',
 
'CR4953',
'CS0412',
'CR4960',
'CO8899',
'CR4958',
'CS0436',
'CQ2508',
'CR4956',
'CS0411',
'CS0603',
'CR4957',
'CS0434',
 
'CR4955',
'CS0437');
CONCAT(REGEXP_REPLACE (TO_CHAR (TO_DATE(:P_INVOICED_START,'YYYY/MM/DD hh24:mi:ss' ), 'Month'), '[[:space:]]', ''),
                                           TO_CHAR(TO_DATE(:P_INVOICED_START,'YYYY/MM/DD hh24:mi:ss' ),  ' DD, YYYY' )) START_1,
         CONCAT(REGEXP_REPLACE (TO_CHAR (TO_DATE(:P_INVOICED_END,'YYYY/MM/DD hh24:mi:ss' ), 'Month'), '[[:space:]]', ''),
                                           TO_CHAR(TO_DATE(:P_INVOICED_END,'YYYY/MM/DD hh24:mi:ss' ),  ' DD, YYYY' )) END_1

SELECT CONCAT(REGEXP_REPLACE (TO_CHAR (TO_DATE(:P_INVOICED_START,'YYYY/MM/DD hh24:mi:ss' ), 'Month'), '[[:space:]]', ''),
                                           TO_CHAR(TO_DATE(:P_INVOICED_START,'YYYY/MM/DD hh24:mi:ss' ),  ' DD, YYYY' ))
FROM DUAL;
SELECT *
FROM RA_cUSTOMER_TRX_ALL
WHERE TRX_NUMBER = '40300001714';

SELECT *
FROM IPC_AR_INVOICES_WITH_CM;
SELECT INTERFACE_LINE_ATTRIBUTE11
FROM RA_CUSTOMER_tRX_LINES_ALL
WHERE CUSTOMER_TRX_ID = 78582;

select *
from mtl_serial_numbers;
SELECT mmts.*
                                FROM mtl_material_transactions mmts
                                                LEFT JOIN mtl_transaction_types mtt
                                                    ON mmts.transaction_type_id = mtt.transaction_type_id
                                WHERE  1 = 1  
                                              and mtt.transaction_type_name IN ('Sales order issue', 'Sales Order Pick')
                                              and mmts.trx_source_line_id = 1258535;
-- 
select sales_order_line
from ra_customer_trx_all
where trx_number = '40300010789';

select sales_order_line
from ra_customer_trx_lines_all
where customer_trx_id = 606801;


SELECT msn.serial_number                         cs_number,
                                                                                   msn.attribute2                            chassis_number,
                                                                                   msib.segment1                             prod_model,
                                                                                   msib.description                          prod_model_desc,
                                                                                   msib.attribute9                           sales_model,
                                                                                   msib.attribute8                           body_color,
                                                                                   msn.attribute4                            body_number,
                                                                                   msn.lot_number,
                                                                                   we.wip_entity_name                        shop_order_number,
                                                                                   mis.serial_no                             serial_number,
                                                                                   msib.attribute11 || ' ' || msn.attribute3 engine,
                                                                                   msib.attribute19 || ' ' || msn.attribute7 aircon,
                                                                                   msib.attribute20 || ' ' || msn.attribute9 stereo,
                                                                                   msn.attribute6                            key_no,
                                                                                   msn.attribute5                            buyoff_date,
                                                                                   msn.attribute11                           fm_date,
                                                                                   msn.attribute15                           mr_date,
                                                                                   msn.attribute1                            csr_number,
                                                                                   msn.attribute12                           csr_or_number,
                                                                                   msn.attribute14                           csr_date,
                                                                                   NULL                                      tagged_date,
                                                                                   ooha.order_number,
                                                                                   ooha.ordered_date,
                                                                                   rcta.trx_number,
                                                                                   rcta.trx_date,
                                                                                   rcta.attribute5 pullout_date,
                                                                                                rcta.attribute4 wb_number,
                                                                                  hp.party_name,
                                                                                   hcaa.account_name,
                                                                                   hcaa.cust_account_id customer_id,
                                                                                   mt.organization_code,
                                                                                                   msn.current_subinventory_code,
                                                                                                   'Oracle' source
                                                                  FROM mtl_serial_numbers msn
                                                                                                LEFT JOIN mtl_system_items_b msib
                                                                                                                                ON msn.inventory_item_id = msib.inventory_item_id
                                                                                                                                and msn.current_organization_id = msib.organization_id
                                                                                                   LEFT JOIN mtl_parameters mt
                                                                                                  ON msib.organization_id = mt.organization_id
                                                                                   LEFT JOIN (SELECT mmts.*
                                                                                                                                  FROM mtl_material_transactions mmts
                                                                                                                                                   LEFT JOIN mtl_transaction_types mtt
                                                                                                                                                                  ON mmts.transaction_type_id = mtt.transaction_type_id
                                                                                                                                WHERE  1 = 1  and mtt.transaction_type_name IN ('Sales order issue', 'Sales Order Pick')
                                                                                                                                ) mmt
                                                                                                   ON msn.last_transaction_id = mmt.transaction_id
                                                                                   LEFT JOIN oe_order_lines_all oola
                                                                                                   ON mmt.trx_source_line_id = oola.line_id
                                                                                   LEFT JOIN oe_order_headers_all ooha
                                                                                                   ON oola.header_id = ooha.header_id
                                                                                   LEFT JOIN wsh_delivery_details wdd
                                                                                                   ON oola.line_id = wdd.source_line_id
                                                                                   LEFT JOIN wsh_delivery_assignments wda
                                                                                                   ON wdd.delivery_detail_id = wda.delivery_detail_id
                                                                                   LEFT JOIN wsh_new_deliveries wnd
                                                                                                   ON wda.delivery_id = wnd.delivery_id
                                                                                   LEFT JOIN hz_cust_accounts_all hcaa
                                                                                                  ON oola.sold_to_org_id = hcaa.cust_account_id
                                                                                   LEFT JOIN hz_parties hp 
                                                                                                  ON hcaa.party_id = hp.party_id
                                                                                   LEFT JOIN xxxipc_mis mis 
                                                                                                  ON msn.serial_number = mis.cs_no
                                                                                   LEFT JOIN wip_entities we
                                                                                                  ON msn.original_wip_entity_id = we.wip_entity_id
                                                                                   LEFT JOIN ra_customer_trx_all rcta
                                                                                                  ON wnd.delivery_id = rcta.interface_header_attribute3
                                                                                                LEFT JOIN (  SELECT customer_trx_id,
                                                                                                                                                                                interface_line_attribute6 so_line_id,
                                                                                                                                                                                SUM (LINE_RECOVERABLE)  net_amount,
                                                                                                                                                                                SUM (TAX_RECOVERABLE)   vat_amount
                                                                                                                                                                FROM ra_customer_trx_lines_all
                                                                                                                                                   WHERE  line_type = 'LINE'
                                                                                                                                                GROUP BY customer_trx_id, interface_line_attribute6) rctla
                                                                                                   ON rcta.customer_trx_id = rctla.customer_trx_id
                                                                                                   AND oola.line_id = rctla.so_line_id
                                                                WHERE 1 = 1 
                                                                              AND msn.c_attribute30 IS NULL
                                                                                and rcta.trx_number = '40300001798';
                                                                            --    AND msib.item_type = 'FG'
                                                                              --  and msn.serial_number = 'CP5322';



SELECT
                  MAX(D.CUSTOMER_NAME) CUSTOMER_NAME,
                  MAX(E.ACCOUNT_NAME) ACCOUNT_NAME,
                  MAX(A.ATTRIBUTE9) SALES_MODEL,
                  A.SEGMENT1 PART_NUMBER, 
                  MAX(A.DESCRIPTION) PART_DESC, 
                  MAX(A.ATTRIBUTE8) BODY_COLOR,
                  MAX(B.LOT_NUMBER) LOT_NUMBER, 
                  MAX(B.SERIAL_NUMBER) CS_NO,
                  MAX(B.ATTRIBUTE2) VIN_NUMBER,
                  MAX(B.ATTRIBUTE3) ENGINE_NO, 
                  MAX(A.ATTRIBUTE11) ENGINE,
                  MAX(C.TRX_NUMBER) INVOICE_NO,
                  SUM(DECODE(
                  F.INTERFACE_LINE_ATTRIBUTE11,'0',F.LINE_RECOVERABLE+F.TAX_RECOVERABLE,0)) 
                  + SUM(DECODE(F.INTERFACE_LINE_ATTRIBUTE11,'0',0,F.LINE_RECOVERABLE+F.TAX_RECOVERABLE)) INVOICE_AMOUNT,
                  SUM(F.TAX_RECOVERABLE) TAX,
                  CASE WHEN SUM(DECODE(F.INTERFACE_LINE_ATTRIBUTE11,'0',0,F.LINE_RECOVERABLE)) > 0
                  THEN 0
                  ELSE SUM(DECODE(F.INTERFACE_LINE_ATTRIBUTE11,'0',0,F.LINE_RECOVERABLE))
                  END
                  DISCOUNT,
                  CASE 
                      WHEN REGEXP_LIKE(MAX(C.TRX_DATE), '^[0-9]{2}-\w{3}-[0-9]{2}$') THEN TO_CHAR(MAX(C.TRX_DATE),'YYYY-MM-DD')
                      WHEN REGEXP_LIKE(MAX(C.TRX_DATE), '^[0-9]{2}-\w{3}-[0-9]{4}$') THEN TO_CHAR(MAX(C.TRX_DATE),'YYYY-MM-DD')
                      WHEN REGEXP_LIKE(MAX(C.TRX_DATE), '^[0-9]{4}/[0-9]{2}/[0-9]{2}') THEN TO_CHAR(TO_DATE(MAX(C.TRX_DATE),'YYYY/MM/DD HH24:MI:SS'),'YYYY-MM-DD')
                      ELSE NULL    
                  END INVOICE_DATE,
                  MAX(C.ATTRIBUTE5) PULLOUT_DATE,
                  CASE 
                      WHEN REGEXP_LIKE(MAX(C.CREATION_DATE), '^[0-9]{2}-\w{3}-[0-9]{2}$') THEN TO_CHAR(MAX(C.CREATION_DATE),'YYYY-MM-DD HH24:MI:SS')
                      WHEN REGEXP_LIKE(MAX(C.CREATION_DATE), '^[0-9]{2}-\w{3}-[0-9]{4}$') THEN TO_CHAR(MAX(C.CREATION_DATE),'YYYY-MM-DD HH24:MI:SS')
                      WHEN REGEXP_LIKE(MAX(C.CREATION_DATE), '^[0-9]{4}/[0-9]{2}/[0-9]{2}') THEN TO_CHAR(TO_DATE(MAX(C.CREATION_DATE),'YYYY/MM/DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS')
                      ELSE NULL    
                  END CREATION_DATE
              FROM MTL_SYSTEM_ITEMS_B A, 
                  MTL_SERIAL_NUMBERS B,
                  RA_CUSTOMER_TRX_ALL C,
                  AR_CUSTOMERS D,
                  HZ_CUST_ACCOUNTS E, 
                  RA_CUSTOMER_TRX_LINES_ALL F,
                  RA_CUSTOMER_TRX_ALL G
              WHERE
                  A.INVENTORY_ITEM_ID = B.INVENTORY_ITEM_ID       
                  AND A.ORGANIZATION_ID = B.CURRENT_ORGANIZATION_ID
                  AND B.SERIAL_NUMBER = C.ATTRIBUTE3
                  AND C.BILL_TO_CUSTOMER_ID = D.CUSTOMER_ID
                  AND D.CUSTOMER_NUMBER = E.ACCOUNT_NUMBER
                  AND C.CUSTOMER_TRX_ID = F.CUSTOMER_TRX_ID
                  AND A.ORGANIZATION_ID IN (121,107)
                  AND B.CURRENT_SUBINVENTORY_CODE = 'STG'
                  and C.customer_trx_id = G.previous_customer_trx_id(+)
                  AND TO_CHAR(C.CREATION_DATE,'YYYY-MM-DD HH24:MI:SS') > '$creation_date'
                  AND G.previous_customer_trx_id is null
                  AND C.previous_customer_trx_id is null
                  and c.trx_number = '40300010789'
              GROUP BY C.TRX_NUMBER,A.SEGMENT1

;

select *
from ra_customer_trx_all
where trx_number = '40300010789';

select *
from ra_customer_trx_lines_all
where customer_Trx_id = 606801;


select distinct ra_head.customer_trx_id,
                   hp.party_name,
                   case
                          when hcaa.account_name in ('IPC Teammembers', 'IPC Teammembes') then null
                       else hcaa.account_name
                   end account_name,
                   case
                          when hcaa.account_name not in ('IPC Teammembers', 'IPC Teammembes')  then null
                       else hcaa.account_name
                   end employee,
                   ra_head.trx_number,
                hcaa.account_number,
                   CASE
                          WHEN HL.ADDRESS1 LIKE 'DEALERS%' THEN HL.ADDRESS2||' '||HL.ADDRESS3
                       ELSE HL.ADDRESS1||' '||HL.ADDRESS2||' '||HL.ADDRESS3||''||HL.CITY
                   END ADDRESS,
                   hcsua.TAX_REFERENCE,
                   ra_head.bill_to_customer_id,
                   ra_head.attribute1,
                   ra_head.bill_to_site_use_id,
                   ra_head.ship_to_customer_id,
                   ra_head.SHIP_TO_SITE_USE_ID,
                   ra_line.inventory_item_id,
                   to_char(ra_head.trx_date, 'Monthdd, yyyy') trx_date,
                rtt.name,
                ra_head.attribute8 CSR,
                ra_head.attribute10 CSR_OR,
                   ra_line.quantity_invoiced,
                   ra_line.unit_selling_price,
                   ra_line.extended_amount,
                   ra_line.tax_recoverable,
                   ra_head.interface_header_attribute1 SO_NUM,
                ra_head.purchase_order PO_NUM,
                   ra_line.interface_line_attribute3 dr_num,
                   ra_line.description model,
                   msn.lot_number lot_no,
                   msn.ATTRIBUTE2 serial_no,
                   msn.attribute3 engine_no,
                   msn.attribute15 body_color,
                   itm.ATTRIBUTE17 fuel,
                   msn.attribute6 key_no,
                   msn.attribute10 tire_brand,
                   msn.attribute8 battery,
                   msn.serial_number cs_no,
                ra_head.attribute4,
                   itm.attribute21 year_model,
                CONCAT(REGEXP_REPLACE (TO_CHAR (TO_DATE(:P_INVOICED_START,'YYYY/MM/DD hh24:mi:ss' ), 'Month'), '[[:space:]]', ''),
                                           TO_CHAR(TO_DATE(:P_INVOICED_START,'YYYY/MM/DD hh24:mi:ss' ),  ' DD, YYYY' )) START_1,
         CONCAT(REGEXP_REPLACE (TO_CHAR (TO_DATE(:P_INVOICED_END,'YYYY/MM/DD hh24:mi:ss' ), 'Month'), '[[:space:]]', ''),
                                           TO_CHAR(TO_DATE(:P_INVOICED_END,'YYYY/MM/DD hh24:mi:ss' ),  ' DD, YYYY' )) END_1

from RA_Customer_Trx_All ra_head,
     RA_Customer_Trx_Lines_All ra_line,
     MTL_SYSTEM_ITEMS itm,
     mtl_serial_numbers msn,
     hz_cust_accounts_all hcaa,
     hz_cust_acct_sites_all hcasa,
     hz_party_sites hps,
     hz_parties hp,
     hz_locations hl,
     hz_cust_site_uses_all hcsua,
     ra_terms_tl rtt,
     (SELECT mtt.transaction_id,
               mtt.trx_source_line_id,
               mtt.inventory_item_id,
               mtt.organization_id,
               mut.serial_number,
               mtlv.lot_number
      FROM (SELECT *
            FROM MTL_UNIT_TRANSACTIONS_ALL_V
            WHERE TRANSACTION_SOURCE_TYPE_ID = 2) MUT,
           (SELECT *
            FROM MTL_TRANSACTION_LOT_VAL_V
            WHERE transaction_source_type_id = 2 AND STATUS_ID = 1) MTLV,
           (SELECT *
            FROM mtl_material_transactions
            WHERE TRANSACTION_SOURCE_TYPE_ID = 2
                    AND TRANSACTION_TYPE_ID = 33) mtt
      WHERE 1 = 1
              --and MUT.serial_number = '104-21' and MUT.organization_id = 89 and MUT.inventory_item_id = 18795
              AND mut.transaction_id = mtlv.serial_transaction_id
              AND mtlv.transaction_id = mtt.transaction_id
              AND mtlv.transaction_source_type_id = mtt.transaction_source_type_id
              AND mtlv.transaction_source_id = mtt.transaction_source_id
              AND mut.transaction_source_id = mtlv.transaction_source_id) MTT1
where ra_head.customer_trx_id = ra_line.customer_trx_id
      and ra_head.org_id = ra_line.org_id
      and itm.inventory_item_id = ra_line.inventory_item_id
      and itm.organization_id = ra_line.warehouse_id
      and ra_line.line_type = 'LINE'
      and ra_head.complete_flag = 'Y'
      and mtt1.trx_source_line_id = ra_line.interface_line_attribute6
      AND msn.serial_number = mtt1.serial_number
      AND msn.inventory_item_id = mtt1.inventory_item_id
      and ra_line.interface_line_attribute11 = 0
      AND ra_head.sold_to_customer_id = hcaa.cust_account_id
         and hcaa.cust_account_id = hcasa.cust_account_id
         AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
         AND hps.location_id = hl.location_id
         AND hps.party_site_id = hcasa.party_site_id
         and hcaa.party_id = hp.party_id
         and ra_head.bill_to_site_use_id = hcsua.SITE_USE_ID
         and ra_head.term_id = rtt.term_id
      and ra_head.org_id = 82
      --and ra_head.trx_number between :INV1 and :INV2
      AND CASE WHEN REGEXP_LIKE(ra_head.trx_date, '^[0-9]{2}-\w{3}-[0-9]{2}$') THEN TO_DATE(ra_head.trx_date,'DD-MON-RRRR')
            WHEN REGEXP_LIKE(ra_head.trx_date, '^[0-9]{2}-\w{3}-[0-9]{4}$') THEN TO_DATE(ra_head.trx_date,'DD-MON-RRRR')
            WHEN REGEXP_LIKE(ra_head.trx_date, '^[0-9]{4}/[0-9]{2}/[0-9]{2}') THEN TO_DATE(TO_DATE(ra_head.trx_date,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-RRRR')
            ELSE NULL
            END
         BETWEEN to_date(SUBSTR(:P_INVOICED_START,1,10),'YYYY/MM/DD') AND to_date(SUBSTR(:P_INVOICED_END,1,10),'YYYY/MM/DD')
order by ra_head.trx_number asc
