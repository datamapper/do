DROP DATABASE rbmysql_test;

CREATE DATABASE rbmysql_test;

USE rbmysql_test;

CREATE TABLE `invoices` (
	`id` int(11) NOT NULL auto_increment,
	`invoice_number` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `widgets` (
  `id` int(11) NOT NULL auto_increment,
	`code` char(8) default 'A14' NULL,
  `name` varchar(200) default 'Super Widget' NULL,
  `shelf_location` tinytext NULL,
	`description` text NULL,
	`image_data` blob NULL,
	`ad_description` mediumtext NULL,
	`ad_image` mediumblob NULL,
	`whitepaper_text` longtext NULL,
	`cad_drawing` longblob NULL,
	`flags` tinyint(1) default "0",
	`number_in_stock` smallint default 500,
	`number_sold` mediumint default 0,
	`super_number` bigint default 9223372036854775807,
	`weight` float default 1.23,
	`cost1` double(8,2) default 10.23,
	`cost2` decimal(8,2) default 50.23,
	`release_date` date default '2008-02-14',
	`release_datetime` datetime default '2008-02-14 00:31:12',
	`release_timestamp` timestamp default '2008-02-14 00:31:31',
	`status` enum('active','out of stock') NOT NULL default 'active',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000001', 'Widget 1', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000002', 'Widget 2', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000003', 'Widget 3', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000004', 'Widget 4', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000005', 'Widget 5', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000006', 'Widget 6', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000007', 'Widget 7', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000008', 'Widget 8', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000009', 'Widget 9', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000010', 'Widget 10', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000011', 'Widget 11', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000012', 'Widget 12', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000013', 'Widget 13', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000014', 'Widget 14', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000015', 'Widget 15', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing) VALUES ('W0000016', 'Widget 16', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING');