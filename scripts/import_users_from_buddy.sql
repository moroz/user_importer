DELETE FROM user_data_dev.roles;
DELETE FROM user_data_dev.users;
delete r from buddy_development.roles r left join buddy_development.users u on r.user_id = u.id where u.id is null;
INSERT INTO user_data_dev.users (id, email, display_name, city, country, phone, inserted_at, updated_at) SELECT id, email, display_name, city, country, phone, created_at AS inserted_at, updated_at FROM buddy_development.users;
INSERT INTO user_data_dev.roles (id, title, user_id, inserted_at, updated_at) SELECT id, title, user_id, created_at AS inserted_at, updated_at FROM buddy_development.roles;
