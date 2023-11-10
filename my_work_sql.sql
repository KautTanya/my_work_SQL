--Скільки співробітників які працюють в одному і тому ж відділі та отримують
--однакову зарплату?
select  mp.department_id, 
        mp.salary,
        COUNT(mp.employee_id) as cnt_job_id
from hr.employees mp
group by mp.department_id, mp.salary
having COUNT(mp.employee_id)>1
order by 2;

--Отримати звіт скільки співробітників прийняли на роботу кожного дня тижня.
select  to_char(mp.HIRE_DATE, 'day') as day,
        count(*) as count
from hr.employees mp
 group by to_char(mp.HIRE_DATE, 'day')
 order by 2;
 
 --Отримати список усіх співробітників, замінивши у значенні
--PHONE_NUMBER все '.' на null;
select  mp.EMPLOYEE_ID, 
        mp.FIRST_NAME, 
        mp.LAST_NAME, EMAIL, 
        replace(mp.PHONE_NUMBER, '.', '') as phone_number, 
        mp.HIRE_DATE, 
        mp.JOB_ID, 
        mp.SALARY, 
        mp.COMMISSION_PCT, 
        mp.MANAGER_ID, 
        mp.DEPARTMENT_ID
from hr.employees mp;

--Отримати максимальну зарплату серед усіх середніх зарплат у
--департаменті;
select max(avg_sal)as max_sal
from 
      (select mp.department_id,
       round(avg(mp.salary)) as avg_sal
       FROM hr.employees mp
       group by mp.department_id
       order by 2) t
;
--Вивести дані з таблиці продуктів, за якими були продажі
select pr.product_id,
       pr.product_name,
       pr.count_product,
       pr.price_sales
        
from hr.products pr
where exists ( select 1 from hr.sales sl 
                where sl.product_id = pr.product_id 
                and sl.count_sales>0)
;
--Створити SQL запит, який завжди буде виводити дані з продажу за
--попередній місяць.
select *
from hr.sales sl
where sl.dt_operations between add_months(trunc(sysdate, 'mm'), -1) and  trunc(sysdate, 'mm') - interval '1' second;

--Отримати список усіх співробітників, які прийшли на роботу в серпні та
--версні в 2005-му році.
select *
from HR.employees mp
where mp.hire_date between add_months(trunc(sysdate,'mm'),-1) - interval '18' year and add_months(trunc(sysdate,'mm'),1) - interval '18' year - interval '1' second
order by mp.hire_date;

--Створити в'ю, на основі запиту, який завжди буде вибирати топ 3
--співробітників, які прийшли в нашу компанію нещодавно.
create view tetyana_ozk.top_3_young_emp as
        select t.*
        from(
            select *
            from hr.employees mp
            order by mp.hire_date desc)t
        where rownum <4;
        
--Вивести всі дані з таблиці продажів, поля – все крім id співробітника.
--Додати у вибірку поля – ім'я, прізвище, телефон, пошту та зарплату з
--таблиці співробітників. Вивести дані лише за
--поточний місяць. Доповнити звіт одним полем – назва посади (з таблиці
--посади). Також додати фільтр, вивести співробітників тільки з посадою
--Sales Representative.
select mp.first_name,
       mp.last_name,
       mp.phone_number,
       mp.email,
       mp.salary,
       sl.dt_operations,
       sl.product_id,
       sl.count_sales,
       sl.sum_sales,
       j.job_title
from hr.employees mp
inner join hr.sales sl
on mp.employee_id = sl.employee_id
inner join hr.jobs j
on mp.job_id = j.job_id
where sl.dt_operations between trunc(sysdate, 'mm') and add_months(trunc(sysdate, 'mm'), 1) - 1/64300
and j.job_title = 'Sales Representative'
;

--Отримати список регіонів та кількість співробітників у кожному регіоні.
select nvl(t3.region_id, rg.region_id) as region_id,
       nvl(rg.region_name,'NOT FOUNDED') as region_name,
       nvl(t3.count_emp,0)as count_emp
from 
            (select t2.region_id,
                    sum(t2.empl_dep)as count_emp
            from              (select t.department_id,
                               nvl(dp.location_id, 0) as location_id,
                               nvl(lc.country_id, 'Not Founded'),
                               nvl(cn.region_id, 0) as region_id,
                               t.empl_dep
                        from
                                (select nvl(mp.department_id, 0) as department_id,
                                       count(nvl(mp.department_id, 0)) as empl_dep
                                from hr.employees mp
                                group by nvl(mp.department_id, 0)
                                order by 1) t
                        left outer join hr.departments dp
                        on t.department_id = dp.department_id
                        left outer join hr.locations lc
                        on lc.location_id = dp.location_id
                        left outer join hr.countries cn
                        on lc.country_id = cn.country_id) t2
            group by t2.region_id) t3
full outer join hr.regions rg
on t3.region_id = rg.region_id
;

--Вивести ід продуктів, яких немає у таблиці продажів. Далі, на
--основі цих ід, вивести назву продуктів, кількість продуктів та ціну
select t.product_id,
       pr.product_name,
       pr.count_product,
       pr.price_sales
from
(select pr.product_id
from hr.products pr
minus
select sl.product_id
from hr.sales sl) t
inner join hr.products pr
on pr.product_id = t.product_id
order by 1
;

--З таблиці посад вивести всі стовпці і зробити підсумковий рядок
--із сумою за мінімальною ЗП та максимальною ЗП.
select *
from hr.jobs jb
union
select 'Всього', 'разом', sum(jb.min_salary), sum(jb.max_salary)
from hr.jobs jb;

--На основі таблиці currency_history, створити SQL запит, який при виконанні 
--буде показувати актуальні топ-3 валюти з найбільшими змінами за весь період.
select *
from (
        select cr.currency_txt,  
               max(cr.currency_value) as max_value, 
               min(cr.currency_value) as min_value,
               round((((max(cr.currency_value)- min(cr.currency_value)) / min(cr.currency_value)) *100),2) as percent_different
        from proj.currency_history cr
        group by cr.currency_txt
        order by round((((max(cr.currency_value)- min(cr.currency_value)) / min(cr.currency_value)) *100),2) desc)
where rownum <4;

