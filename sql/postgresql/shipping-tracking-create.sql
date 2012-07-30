-- shipping-tracking-create.sql
--
-- @author Dekka Corp.
-- @ported from sql-ledger and combined with parts from OpenACS ecommerce package
-- @license GNU GENERAL PUBLIC LICENSE, Version 2, June 1991
-- @cvs-id
--

--  this is from SL, but we're moving the address into contacts package

create table ecst_shipto (
  trans_id int,
  shiptoname varchar(64),
  shiptoaddress1 varchar(32),
  shiptoaddress2 varchar(32),
  shiptocity varchar(32),
  shiptostate varchar(32),
  shiptozipcode varchar(10),
  shiptocountry varchar(32),
  shiptocontact varchar(64),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);

--
create index ecst_shipto_trans_id_key on ecst_shipto (trans_id);

-- we need to import the ecommerce shipping-tracking model here

-- this is needed because orders might be only partially shipped
-- create sequence ecst_shipment_id_seq;
   create view ecst_shipment_id_sequence as select nextval('ecst_shipment_id_seq') as nextval;
   
   create table ecst_shipments (
           shipment_id             integer not null primary key,
           order_id                integer not null references qar_ec_orders,
           -- usually, but not necessarily, the same as the shipping_address
           -- in ecst_orders because a customer may change their address between
           -- shipments.
           -- a trigger fills address_id in automatically if it's null
           address_id              integer references qal_ec_addresses,
           shipment_date           timestamptz not null,
           expected_arrival_date   timestamptz,
           carrier                 varchar(50),    -- e.g., 'fedex'
           tracking_number         varchar(24),
           -- only if we get confirmation from carrier that the goods
           -- arrived on a specific date
           actual_arrival_date     timestamptz,
           -- arbitrary info from carrier, e.g., 'Joe Smith signed for it'
           actual_arrival_detail   varchar(4000),
           -- for things that aren't really shipped like services
           shippable_p             boolean default 't',
           last_modified           timestamptz,
           last_modifying_user     integer,
           modified_ip_address     varchar(20)
   );
   
   create index ecst_shipments_by_order_id on ecst_shipments(order_id);
   create index ecst_shipments_by_shipment_date on ecst_shipments(shipment_date);
   
   -- fills address_id into ecst_shipments if it's missing
   -- (using the shipping_address associated with the order)

   create function ecst_shipment_address_update_tr ()
   returns opaque as '
   declare
           v_address_id            qal_ec_addresses.address_id%TYPE;
   begin
           select into v_address_id shipping_address 
   	from ecst_orders where order_id=new.order_id;
           IF new.address_id is null THEN
                   new.address_id := v_address_id;
           END IF;
   	return new;
   end;' language 'plpgsql';
   
   create trigger ecst_shipment_address_update_tr
   before insert on ecst_shipments
   for each row execute procedure ecst_shipment_address_update_tr ();
   
   create table ecst_shipments_audit (
           shipment_id             integer,
           order_id                integer,
           address_id              integer,
           shipment_date           timestamptz,
           expected_arrival_date   timestamptz,
           carrier                 varchar(50),
           tracking_number         varchar(24),
           actual_arrival_date     timestamptz,
           actual_arrival_detail   varchar(4000),
           last_modified           timestamptz,
           last_modifying_user     integer,
           modified_ip_address     varchar(20),
           delete_p                boolean default 'f'
   );
   
   create function ecst_shipments_audit_tr ()
   returns opaque as '
   begin
           insert into ecst_shipments_audit (
           shipment_id, order_id, address_id,
           shipment_date, 
           expected_arrival_date,
           carrier, tracking_number,
           actual_arrival_date, actual_arrival_detail,
           last_modified,
           last_modifying_user, modified_ip_address
           ) values (
           old.shipment_id, old.order_id, old.address_id,
           old.shipment_date,
           old.expected_arrival_date,
           old.carrier, old.tracking_number,
           old.actual_arrival_date, old.actual_arrival_detail,
           old.last_modified,
           old.last_modifying_user, old.modified_ip_address      
           );
   	return new;
   end;' language 'plpgsql';
   
   create trigger ecst_shipments_audit_tr
   after update or delete on ecst_shipments
   for each row execute procedure ecst_shipments_audit_tr ();

