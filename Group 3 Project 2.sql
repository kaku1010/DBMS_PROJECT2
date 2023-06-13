
--在2000年上映，平均評分分數大於4的電影編號、電影名稱。

--建立INDEX但不一定會強制執行
-- CREATE UNIQUE INDEX PUBLISHED_YEAR ON MOVIE(YEAR); 
--強制執行INDEX
-- SELECT /*+ INDEX (MOVIE(YEAR)) */ DISTINCT MOVIE.MOVIE_ID, MOVIE.NAME

--用於刪除各種INDEX
--DROP INDEX RATING_USER_RATING_IDX; 
--DROP INDEX IDX_RATING_MOVIE_ID;
--DROP INDEX IDX_RATING_RATING;
--DROP INDEX NAME_IDX;
--DROP INDEX MOVIE_YEAR_IDX;
--DROP INDEX MOVIE_ID;

--查詢句一：
SELECT /*+ INDEX (RATING(MOVIE_ID)) */ DISTINCT MOVIE.MOVIE_ID, MOVIE.NAME 
FROM MOVIE, RATING
WHERE RATING.MOVIE_ID = MOVIE.MOVIE_ID AND RATING.RATING > 4 AND MOVIE.YEAR = 2000;

--查詢句二：
SELECT DISTINCT M.MOVIE_ID, M.NAME
FROM (SELECT /*+ INDEX ((MOVIE(YEAR)) */ * FROM MOVIE WHERE YEAR = 2000) M, (SELECT /*+ INDEX ((RATING(RATING)) */ * FROM RATING WHERE RATING > 4) R
WHERE M.MOVIE_ID = R.MOVIE_ID;

-- 用來查詢目前的所有INDEX (在固定權限下)
select ind.index_name,
       ind_col.column_name,
       ind.index_type,
       ind.uniqueness,
       ind.table_owner as schema_name,
       ind.table_name as object_name,
       ind.table_type as object_type       
from sys.all_indexes ind
inner join sys.all_ind_columns ind_col on ind.owner = ind_col.index_owner
                                    and ind.index_name = ind_col.index_name
-- excluding some Oracle maintained schemas
where ind.owner not in ('ANONYMOUS','CTXSYS','DBSNMP','EXFSYS', 'LBACSYS', 
   'MDSYS', 'MGMT_VIEW','OLAPSYS','OWBSYS','ORDPLUGINS', 'ORDSYS','OUTLN', 
   'SI_INFORMTN_SCHEMA','SYS','SYSMAN','SYSTEM', 'TSMSYS','WK_TEST',
   'WKPROXY','WMSYS','XDB','APEX_040000', 'APEX_PUBLIC_USER','DIP', 'WKSYS',
   'FLOWS_30000','FLOWS_FILES','MDDATA', 'ORACLE_OCM', 'XS$NULL',
   'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'PUBLIC')
order by ind.table_owner,
         ind.table_name,
         ind.index_name,
         ind_col.column_position;


--找出movie_id<= 5000且評論數 >= 100每部的平均rating分數跟電影名稱，依照電影名稱由Z到A排列

--1
CREATE INDEX NAMEID_IDX ON MOVIE (NAME DESC, MOVIE_ID);

alter session set cursor_sharing=exact;

EXPLAIN PLAN FOR
SELECT /*+INDEX(NAMEID_IDX)*/ distinct M.Name, ROUND(AVG(R.RATING),2) AS average_rating
FROM Movie M, Rating R  
WHERE M.Movie_ID = R.Movie_ID AND M.MOVIE_ID <= '5000' 
GROUP BY M.MOVIE_ID,M.Name
HAVING COUNT(R.RATING) > 100
ORDER BY M.NAME DESC;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE'));


--2

EXPLAIN PLAN FOR
SELECT /*+INDEX(MOVIE ID_NAME_IDX)*/ M.Name, ROUND(AVG(R.RATING), 2) AS average_rating
FROM Movie M
JOIN Rating R ON M.Movie_ID = R.Movie_ID
WHERE M.Movie_ID <= 5000
GROUP BY M.Movie_ID, M.Name
HAVING COUNT(R.RATING) >= 100
ORDER BY M.NAME DESC;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

--3

EXPLAIN PLAN FOR
SELECT ROUND(AVG(R.RATING),2) AS Average_Rating
FROM Movie M
JOIN Rating R ON M.Movie_ID = R.Movie_ID
WHERE M.Movie_ID <= 5000
GROUP BY M.Movie_ID, M.Name
HAVING COUNT(R.Rating) >= 100
AND M.Movie_ID IN (
  SELECT Movie_ID
  FROM Rating
  GROUP BY Movie_ID
  HAVING COUNT(*) >= 100
)
ORDER BY M.NAME DESC;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());


--找出user_id為’712664’這位用戶評分為5的電影名

--1

CREATE INDEX rating_user_rating_idx ON RATING (RATING DESC)--建立索引
 
SELECT MOVIE.NAME
FROM MOVIE, RATING 
WHERE RATING.USER_ID='712664' 
AND RATING.RATING=5 
AND RATING.MOVIE_ID=MOVIE.MOVIE_ID;

--2

SELECT NAME
FROM MOVIE NATURAL JOIN RATING
WHERE USER_ID='712664' AND RATING=5;
