-- shipping-tracking-drop.sql
--
-- @author Dekka Corp.
-- @ported from sql-ledger and combined with parts from OpenACS ecommerce package
-- @license GNU GENERAL PUBLIC LICENSE, Version 2, June 1991
-- @cvs-id
--

--  this is from SL, but we're moving the address into contacts package

   drop trigger ecst_shipments_audit_tr on ecst_shipments;
   
   drop function ecst_shipments_audit_tr ();
   
   drop table ecst_shipments_audit ();

   drop trigger ecst_shipment_address_update_tr on ecst_shipments;
   
   drop function ecst_shipment_address_update_tr ();
   
   drop index ecst_shipments_by_shipment_date on ecst_shipments(shipment_date);
   drop index ecst_shipments_by_order_id on ecst_shipments(order_id);
   
   drop table ecst_shipments ();
   
   drop view ecst_shipment_id_sequence as select nextval('ecst_shipment_id_seq') as nextval;

drop index ecst_shipto_trans_id_key on ecst_shipto (trans_id);


drop table ecst_shipto ();


