
---------------------------------------------------------

-- Developer: Alejandro Hernández Gómez
-- Github: https://github.com/ahrgomez
-- Portfolio: http://www.ahrgomez.com

---------------------------------------------------------

DECLARE @bbdd_name varchar(max)
set @bbdd_name = 'testfk'

exec('use ' + @bbdd_name)
GO
		DECLARE @delete_referential_action_cascade int = 0

		DECLARE @table_name varchar(max)
		set @table_name = 'candidatos'

		DECLARE @table_column_id varchar(max)
		set @table_column_id = 'id_candidato'

		DECLARE @table_object_id int
		set @table_object_id = (select object_id from sys.tables where name = @table_name)
		
		declare @tables_with_foreign_keys table(object_id int);
		declare @tables_with_column_id table(object_id int);
		declare @tables_with_column_id_without_foreign_key table(object_id int, table_name varchar(max));
		declare @tables_with_foreign_key_without_column_id table(object_id int);

		--Get's tables with foreign key
		insert into @tables_with_foreign_keys
		select parent_object_id from sys.foreign_keys where referenced_object_id = @table_object_id

		--Get's tables with a column id
		insert into @tables_with_column_id
		select object_id from sys.tables where name in (select table_name from  [INFORMATION_SCHEMA].[COLUMNS] where column_name = @table_column_id) and object_id <> @table_object_id

		--Get's tables with a column id_Candidato without foreign_key
		insert into @tables_with_column_id_without_foreign_key
		select object_id, name from sys.tables where name in (select table_name from  [INFORMATION_SCHEMA].[COLUMNS] where column_name = @table_column_id) and object_id not in (select (case when parent_object_id = @table_object_id then referenced_object_id when referenced_object_id = @table_object_id then parent_object_id end) from sys.foreign_keys where parent_object_id = @table_object_id or referenced_object_id = @table_object_id) and object_id <> @table_object_id

		--Get's tables with foreign key and without column id
		insert into @tables_with_foreign_key_without_column_id
		select object_id from @tables_with_foreign_keys where object_id not in (select object_id from @tables_with_column_id) and object_id <> @table_object_id

		DECLARE @ctable_id int, @ctable_name varchar(max);
		DECLARE table_name_cursor CURSOR FOR 
		select * from @tables_with_column_id_without_foreign_key

		OPEN table_name_cursor

		FETCH NEXT FROM table_name_cursor 
		INTO @ctable_id, @ctable_name

		WHILE @@FETCH_STATUS = 0
		BEGIN

			DECLARE @count int
			DECLARE @sql nvarchar(max) = 'SELECT @count = count(' + @table_column_id + ')  FROM ' + @ctable_name + ' where ' + @table_column_id + ' not in (select ' + @table_column_id + ' from ' + @table_name + ')'

			exec sp_executesql @SQL, N'@count int out', @count out

			DECLARE @addforeignkey nvarchar(max)
			SET @addforeignkey = 'ALTER TABLE ' + @ctable_name + ' WITH CHECK ADD CONSTRAINT fk_' + @ctable_name + '_' + @table_name + ' FOREIGN KEY (' + @table_column_id + ') REFERENCES ' + @table_name + '(' + @table_column_id + ') ON DELETE CASCADE'

			if(@count > 0)
			BEGIN

			DECLARE @deleteOrpahns nvarchar(max) = 'DELETE FROM ' + @ctable_name + ' WHERE ' + @table_column_id + ' NOT IN (Select ' + @table_column_id + ' from ' + @table_name + ')'
		
			exec(@deleteOrpahns)

			PRINT('Deleted ' + @count + ' orphans in table ' + @ctable_name)

			END

			exec(@addforeignkey)

		
			PRINT('Added foreign key with delete on cascade for table ' + @ctable_name)

			FETCH NEXT FROM table_name_cursor 
			INTO @ctable_id, @ctable_name

		END
		CLOSE table_name_cursor;
		DEALLOCATE table_name_cursor;

		DECLARE @tables_with_foreign_keys_without_delete_cascade table(object_id int, foreign_key_name varchar(max));

		--insert into @tables_with_foreign_keys_without_delete_cascade
		select (select name from sys.tables t where t.object_id = object_id) as tablename, name from sys.foreign_keys where referenced_object_id = @table_object_id and delete_referential_action = @delete_referential_action_cascade

		DECLARE @cfk_name varchar(max)

		DECLARE no_cascade_cursor CURSOR FOR 
		select * from @tables_with_foreign_keys_without_delete_cascade

		OPEN no_cascade_cursor

		FETCH NEXT FROM no_cascade_cursor 
		INTO @ctable_name, @cfk_name

		WHILE @@FETCH_STATUS = 0
		BEGIN

			DECLARE @drop_foreign_key varchar(max) = 'ALTER TABLE ' + @ctable_name + ' DROP CONSTRAINT ' + @cfk_name
			DECLARE @add_foreign_key_cascade varchar(max) = 'ALTER TABLE ' + @ctable_name + ' WITH CHECK ADD CONSTRAINT fk_' + @ctable_name + '_' + @table_name + ' FOREIGN KEY (' + @table_column_id + ') REFERENCES ' + @table_name + '(' + @table_column_id + ') ON DELETE CASCADE'

			exec(@drop_foreign_key)

			PRINT('Dropped the foreign key with table ' + @table_name + ' for table ' + @ctable_name)

			exec(@add_foreign_key_cascade)

			PRINT('Added foreign key with delete on cascade for table ' + @ctable_name)
		END
		CLOSE no_cascade_cursor;
		DEALLOCATE no_cascade_cursor;