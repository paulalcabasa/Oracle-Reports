<%@ taglib uri="/WEB-INF/lib/reports_tld.jar" prefix="rw" %> 
<%@ page language="java" import="java.io.*" errorPage="/rwerror.jsp" session="false" %>
<%@ page contentType="text/html;charset=ISO-8859-1" %>
<!--
<rw:report id="report"> 
<rw:objects id="objects">
<?xml version="1.0" encoding="WINDOWS-1252" ?>
<report name="IPC_RPT_2224" DTDVersion="9.0.2.0.10">
  <xmlSettings xmlTag="MODULE1" xmlPrologType="text">
  <![CDATA[<?xml version="1.0" encoding="&Encoding"?>]]>
  </xmlSettings>
  <data>
    <userParameter name="P_START" datatype="character" width="40"
     defaultWidth="0" defaultHeight="0"/>
    <userParameter name="P_END" datatype="character" width="40"
     defaultWidth="0" defaultHeight="0"/>
    <dataSource name="Q_1">
      <select canParse="no">
      <![CDATA[select 
       a.jo_number,
       a.lot_number,
       a.serial_number as cs_number,
       a.item,
       a.description,       
       a.item_category_family,
       a.item_category_class,
       a.item_type,
       to_date(wip_completion_date) as wip_completion_date,
       sum(decode(trans_name, 'WIP Completion', actual_cost, null)) "WIP Completion Cost",
       sum(decode(trans_name, 'Sales order issue', actual_cost, null)) "Sales order issue Cost",
       sum(decode(trans_name, 'Direct Org Transfer FG - VSS', actual_cost, null)) "FG - VSS",
       sum(decode(trans_name, 'Direct Org Transfer VSS - FG', actual_cost, null)) "VSS - FG",
       sum(decode(trans_name, 'Direct Org Transfer NYK - VSS', actual_cost, null)) "NYK - VSS",       
       sum(decode(trans_name, 'Direct Org Transfer VSS - NYK', actual_cost, null)) "VSS - NYK",
    b.invoice_amount,
    b.cogs_amount
from 
(SELECT  
       mmt.inventory_item_id,
          msib.segment1 as item,
    msib.description,       
        mck.segment1  as item_category_family,
    mck.segment2  AS item_category_class,
    msib.item_type,
    min(mmt.transaction_date) OVER(PARTITION BY serial_number) as wip_completion_date,
(CASE
           WHEN b.transaction_type_name = 'Direct Org Transfer'
              THEN    b.transaction_type_name
                   || ' '
                   || (CASE
                          WHEN mmt.transfer_subinventory IS NULL
                             THEN mmt.subinventory_code
                          ELSE    mmt.subinventory_code
                               || ' - '
                               || mmt.transfer_subinventory
                       END
                      )
           ELSE b.transaction_type_name
        END
       ) trans_name,
       mmt.organization_id, mmt.subinventory_code,
       mmt.transfer_organization_id, mmt.transfer_subinventory,
       TO_DATE (mmt.transaction_date) transaction_date,
       CASE
          WHEN b.transaction_type_name = 'WIP Completion'
             THEN mmt.transaction_date
       END AS new_date,
       mut.serial_number, mmt.transaction_id, mmt.transaction_type_id,
       b.transaction_type_name, mmt.actual_cost, mmt.transaction_quantity,
       (SELECT b.wip_entity_name
          FROM mtl_serial_numbers a, wip_discrete_jobs_v b
         WHERE a.original_wip_entity_id = b.wip_entity_id
           AND a.attribute5 IS NOT NULL
           AND a.c_attribute30 IS NULL
           AND a.serial_number = mut.serial_number) AS jo_number,
        '' as lot_number
  FROM mtl_material_transactions mmt,
       mtl_unit_transactions mut,
       mtl_transaction_types b,
        mtl_system_items_b      msib,
        mtl_categories_kfv      mck,
        MTL_ITEM_CATEGORIES     mtc
 WHERE 
  mmt.inventory_item_id = msib.inventory_item_id
         AND mmt.organization_id = msib.organization_id and
 mmt.transaction_id = mut.transaction_id
   AND mmt.transaction_type_id = b.transaction_type_id
   AND mmt.transaction_type_id IN (3, 44, 33)
   AND mtc.CATEGORY_ID = mck.CATEGORY_ID
   AND MCK.STRUCTURE_ID = '50388'
   and   msib.inventory_item_id = mtc.inventory_item_id
     AND mmt.organization_id = mtc.organization_id
UNION
SELECT
       mmt.inventory_item_id,
          msib.segment1 as item,
    msib.description,
        mck.segment1  as item_category_family,
    mck.segment2  AS item_category_class,
    msib.item_type,
         min(mmt.transaction_date) OVER(PARTITION BY serial_number) as wip_completion_date,(CASE
           WHEN b.transaction_type_name = 'Direct Org Transfer'
              THEN    b.transaction_type_name
                   || ' '
                   || (CASE
                          WHEN mmt.transfer_subinventory IS NULL
                             THEN mmt.subinventory_code
                          ELSE    mmt.subinventory_code
                               || ' - '
                               || mmt.transfer_subinventory
                       END
                      )
           ELSE b.transaction_type_name
        END
       ) trans_name,
       mmt.organization_id, mmt.subinventory_code,
       mmt.transfer_organization_id, mmt.transfer_subinventory,
       TO_DATE (mmt.transaction_date) transaction_date,
       CASE
          WHEN b.transaction_type_name = 'WIP Completion'
             THEN mmt.transaction_date
       END AS new_date,
       mut.serial_number, mmt.transaction_id, mmt.transaction_type_id,
       b.transaction_type_name, mmt.actual_cost, mmt.transaction_quantity,
       (SELECT b.wip_entity_name
          FROM mtl_serial_numbers a, wip_discrete_jobs_v b
         WHERE a.original_wip_entity_id = b.wip_entity_id
           AND a.attribute5 IS NOT NULL
           AND a.c_attribute30 IS NULL
           AND a.serial_number = mut.serial_number) AS jo_number,
       lot_number
  FROM mtl_material_transactions mmt,
       mtl_transaction_lot_numbers mtln,
       mtl_unit_transactions mut,
       mtl_transaction_types b ,
          mtl_system_items_b      msib,
          mtl_categories_kfv      mck,
          MTL_ITEM_CATEGORIES     mtc
 WHERE 
  mmt.inventory_item_id = msib.inventory_item_id
         AND mmt.organization_id = msib.organization_id and mmt.transaction_id = mtln.transaction_id
   AND mtln.serial_transaction_id = mut.transaction_id
   AND mmt.transaction_type_id = b.transaction_type_id
   AND mmt.transaction_type_id IN (3, 44, 33)
   AND mtc.CATEGORY_ID = mck.CATEGORY_ID
    and  msib.inventory_item_id = mtc.inventory_item_id
     AND mmt.organization_id = mtc.organization_id
   AND MCK.STRUCTURE_ID = '50388'

) a,
ipc_sales_vs_cogs_v b
where 
a.serial_number = b.cs_number(+)
and a.jo_number is not null  
and wip_completion_date between :p_start and :p_end
--and  cs_number in ('D0I628','D0H444')
group by
a.jo_number,
       a.lot_number,
       a.serial_number,
       a.item,
       a.description,       
       a.item_category_family,
       a.item_category_class,
          a.item_type,
       a.wip_completion_date,
       a.inventory_item_id,
       b.invoice_amount,
       b.cogs_amount
       
       ]]>
      </select>
      <displayInfo x="1.17712" y="1.16663" width="0.69995" height="0.19995"/>
      <group name="G_JO_NUMBER">
        <displayInfo x="0.52478" y="1.86658" width="2.00464" height="1.62695"
        />
        <dataItem name="JO_NUMBER" datatype="vchar2" columnOrder="13"
         width="240" defaultWidth="100000" defaultHeight="10000"
         columnFlags="1" defaultLabel="Jo Number">
          <dataDescriptor expression="JO_NUMBER"
           descriptiveExpression="JO_NUMBER" order="1" width="240"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="LOT_NUMBER" datatype="vchar2" columnOrder="14"
         width="80" defaultWidth="100000" defaultHeight="10000"
         columnFlags="1" defaultLabel="Lot Number">
          <dataDescriptor expression="LOT_NUMBER"
           descriptiveExpression="LOT_NUMBER" order="2" width="80"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="CS_NUMBER" datatype="vchar2" columnOrder="15"
         width="30" defaultWidth="100000" defaultHeight="10000"
         columnFlags="1" defaultLabel="Cs Number">
          <dataDescriptor expression="CS_NUMBER"
           descriptiveExpression="CS_NUMBER" order="3" width="30"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="ITEM" datatype="vchar2" columnOrder="16" width="40"
         defaultWidth="100000" defaultHeight="10000" columnFlags="1"
         defaultLabel="Item">
          <dataDescriptor expression="ITEM" descriptiveExpression="ITEM"
           order="4" width="40"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="DESCRIPTION" datatype="vchar2" columnOrder="17"
         width="240" defaultWidth="100000" defaultHeight="10000"
         columnFlags="1" defaultLabel="Description">
          <dataDescriptor expression="DESCRIPTION"
           descriptiveExpression="DESCRIPTION" order="5" width="240"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="ITEM_CATEGORY_FAMILY" datatype="vchar2"
         columnOrder="18" width="40" defaultWidth="100000"
         defaultHeight="10000" columnFlags="1"
         defaultLabel="Item Category Family">
          <dataDescriptor expression="ITEM_CATEGORY_FAMILY"
           descriptiveExpression="ITEM_CATEGORY_FAMILY" order="6" width="40"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="ITEM_CATEGORY_CLASS" datatype="vchar2"
         columnOrder="19" width="40" defaultWidth="100000"
         defaultHeight="10000" columnFlags="1"
         defaultLabel="Item Category Class">
          <dataDescriptor expression="ITEM_CATEGORY_CLASS"
           descriptiveExpression="ITEM_CATEGORY_CLASS" order="7" width="40"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="ITEM_TYPE" datatype="vchar2" columnOrder="20"
         width="30" defaultWidth="100000" defaultHeight="10000"
         columnFlags="1" defaultLabel="Item Type">
          <dataDescriptor expression="ITEM_TYPE"
           descriptiveExpression="ITEM_TYPE" order="8" width="30"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="WIP_COMPLETION_DATE" datatype="date"
         oracleDatatype="date" columnOrder="21" width="9" defaultWidth="90000"
         defaultHeight="10000" columnFlags="1"
         defaultLabel="Wip Completion Date">
          <dataDescriptor expression="WIP_COMPLETION_DATE"
           descriptiveExpression="WIP_COMPLETION_DATE" order="9" width="9"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="WIP_Completion_Cost" oracleDatatype="number"
         columnOrder="22" width="22" defaultWidth="90000"
         defaultHeight="10000" columnFlags="1"
         defaultLabel="Wip Completion Cost">
          <dataDescriptor expression="WIP Completion Cost"
           descriptiveExpression="WIP Completion Cost" order="10" width="22"
           precision="38"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="Sales_order_issue_Cost" oracleDatatype="number"
         columnOrder="23" width="22" defaultWidth="90000"
         defaultHeight="10000" columnFlags="1"
         defaultLabel="Sales Order Issue Cost">
          <dataDescriptor expression="Sales order issue Cost"
           descriptiveExpression="Sales order issue Cost" order="11"
           width="22" precision="38"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="FG_VSS" oracleDatatype="number" columnOrder="24"
         width="22" defaultWidth="90000" defaultHeight="10000" columnFlags="1"
         defaultLabel="Fg Vss">
          <dataDescriptor expression="FG - VSS"
           descriptiveExpression="FG - VSS" order="12" width="22"
           precision="38"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="VSS_FG" oracleDatatype="number" columnOrder="25"
         width="22" defaultWidth="90000" defaultHeight="10000" columnFlags="1"
         defaultLabel="Vss Fg">
          <dataDescriptor expression="VSS - FG"
           descriptiveExpression="VSS - FG" order="13" width="22"
           precision="38"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="NYK_VSS" oracleDatatype="number" columnOrder="26"
         width="22" defaultWidth="90000" defaultHeight="10000" columnFlags="1"
         defaultLabel="Nyk Vss">
          <dataDescriptor expression="NYK - VSS"
           descriptiveExpression="NYK - VSS" order="14" width="22"
           precision="38"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="VSS_NYK" oracleDatatype="number" columnOrder="27"
         width="22" defaultWidth="90000" defaultHeight="10000" columnFlags="1"
         defaultLabel="Vss Nyk">
          <dataDescriptor expression="VSS - NYK"
           descriptiveExpression="VSS - NYK" order="15" width="22"
           precision="38"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="INVOICE_AMOUNT" oracleDatatype="number"
         columnOrder="28" width="22" defaultWidth="20000"
         defaultHeight="10000" columnFlags="1" defaultLabel="Invoice Amount">
          <dataDescriptor expression="INVOICE_AMOUNT"
           descriptiveExpression="INVOICE_AMOUNT" order="16" width="22"
           scale="-127"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
        <dataItem name="COGS_AMOUNT" oracleDatatype="number" columnOrder="29"
         width="22" defaultWidth="20000" defaultHeight="10000" columnFlags="1"
         defaultLabel="Cogs Amount">
          <dataDescriptor expression="COGS_AMOUNT"
           descriptiveExpression="COGS_AMOUNT" order="17" width="22"
           scale="-127"/>
          <dataItemPrivate adtName="" schemaName=""/>
        </dataItem>
      </group>
    </dataSource>
  </data>
  <reportPrivate versionFlags2="0" templateName="rwbeige"/>
  <reportWebSettings>
  <![CDATA[]]>
  </reportWebSettings>
</report>
</rw:objects>
-->

<html>

<head>
<meta name="GENERATOR" content="Oracle 9i Reports Developer"/>
<title> Your Title </title>

<rw:style id="yourStyle">
   <!-- Report Wizard inserts style link clause here -->
</rw:style>

</head>


<body>

<rw:dataArea id="yourDataArea">
   <!-- Report Wizard inserts the default jsp here -->
</rw:dataArea>



</body>
</html>

<!--
</rw:report> 
-->
