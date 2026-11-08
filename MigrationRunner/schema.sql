
    drop table if exists outbox_messages cascade

    drop table if exists policies cascade

    drop table if exists policy_versions cascade

    drop table if exists policy_covers cascade

    drop table if exists offers cascade

    drop table if exists offer_covers cascade

    create table outbox_messages (
        id  bigserial,
       type varchar(500),
       json_payload text,
       primary key (id)
    )

    create table policies (
        id uuid not null,
       number varchar(255),
       product_code varchar(255),
       status varchar(255),
       agent_login varchar(255),
       creation_date timestamp,
       primary key (id)
    )

    create table policy_versions (
        id uuid not null,
       policy_id uuid,
       version_number int4,
       cover_from timestamp,
       cover_to timestamp,
       valid_from timestamp,
       valid_to timestamp,
       holder_first_name varchar(255),
       holder_last_name varchar(255),
       holder_tax_id varchar(255),
       holder_country varchar(255),
       holder_zip_code varchar(255),
       holder_city varchar(255),
       street varchar(255),
       total_premium decimal(19,5),
       primary key (id)
    )

    create table policy_covers (
        policy_version_id uuid not null,
       cover_code varchar(255),
       premium decimal(19,5),
       valid_from timestamp,
       valid_to timestamp
    )

    create table offers (
        id uuid not null,
       number varchar(255),
       product_code varchar(255),
       policy_from timestamp,
       policy_to timestamp,
       holder_first_name varchar(255),
       holder_last_name varchar(255),
       holder_pesel varchar(255),
       total_price decimal(19,5),
       status int4,
       creation_date timestamp,
       agent_login varchar(255),
       primary key (id)
    )

    create table offer_covers (
        offer_id uuid not null,
       cover_code varchar(255),
       price decimal(19,5)
    )

    alter table policy_versions 
        add constraint FK_751C6BB1 
        foreign key (policy_id) 
        references policies

    alter table policy_covers 
        add constraint FK_C63AB836 
        foreign key (policy_version_id) 
        references policy_versions

    alter table offer_covers 
        add constraint FK_F8493B11 
        foreign key (offer_id) 
        references offers
