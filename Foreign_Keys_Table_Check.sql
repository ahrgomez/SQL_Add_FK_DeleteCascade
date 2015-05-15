
---------------------------------------------------------

-- Developer: Alejandro Hernández Gómez
-- Github: https://github.com/ahrgomez
-- Portfolio: http://www.ahrgomez.com

---------------------------------------------------------

use cpBI_Estandar
GO
		SET NOCOUNT ON;

		DECLARE @delete_referential_action_cascade int = 1
		DECLARE @delete_referential_action_no_action int = 0

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

		--Get's tables with the column_id without foreign_key
		insert into @tables_with_column_id_without_foreign_key
		select object_id, name from sys.tables where name in (select table_name from  [INFORMATION_SCHEMA].[COLUMNS] where column_name = @table_column_id) and object_id not in (select (case when parent_object_id = @table_object_id then referenced_object_id when referenced_object_id = @table_object_id then parent_object_id end) from sys.foreign_keys where parent_object_id = @table_object_id or referenced_object_id = @table_object_id) and object_id <> @table_object_id

		--Get's tables with foreign key and without column id
		insert into @tables_with_foreign_key_without_column_id
		select object_id from @tables_with_foreign_keys where object_id not in (select object_id from @tables_with_column_id) and object_id <> @table_object_id
		
		DECLARE @count_without_foreign_keys int
		set @count_without_foreign_keys = (select count(object_id) from @tables_with_column_id_without_foreign_key)

		if(@count_without_foreign_keys > 0)
		BEGIN
			PRINT('Foreign keys needed for the child tables ' + @table_name + ' of you BBDD')
			PRINT(convert(varchar, @count_without_foreign_keys) + ' child tables finded without foreign keys')
		END
		else
			PRINT('Not Foreign keys needed for the child tables ' + @table_name + '  of you BBDD')

		SET NOCOUNT OFF;