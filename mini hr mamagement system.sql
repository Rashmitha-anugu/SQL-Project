create database practice_project;
use practice_project;
CREATE TABLE Departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    age INT CHECK (age >= 18 AND age <= 65),
    hire_date date,
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id)
);


INSERT INTO Departments (dept_name)
VALUES 
('Human Resources'),
('Engineering'),
('Marketing'),
('Finance');

select * from departments;

INSERT INTO Employees (first_name, last_name, email, age, hire_date, dept_id)
VALUES
('Alice', 'Smith', 'alice.smith@example.com', 30, '2022-01-10', 1),
('Bob', 'Johnson', 'bob.johnson@example.com', 45, '2021-07-22', 2),
('Carol', 'Lee', 'carol.lee@example.com', 28, '2023-03-15', 3),
('David', 'Wong', 'david.wong@example.com', 50, '2020-05-12', 4);

select * from employees;

/*
Q1. Retrieve all employees' full names, their email, and the department they work in.
(Hint: Use JOIN)
Q2. Find all employees who joined before January 1, 2022.
Q3. Get the count of employees in each department.
Q4. List all departments with no employees yet.
(Hint: Use LEFT JOIN)
*/

-- Q1. Retrieve all employees' full names, their email, and the department they work in.
select e.First_Name,e.last_name,e.email,d.dept_name
from employees as e
join departments as d
on e.dept_id=d.dept_id;

-- Q2. Find all employees who joined before January 1, 2022.
select * from employees
where hire_date < '2022-01-01';

-- Q3. Get the count of employees in each department.
select count(dept_id),dept_name from departments
group by dept_id; -- it may give inconsistent results

-- correct query is by joining tables for better readbility
select d.dept_name,count(e.emp_id) as emp_count
from employees as e
left join departments as d
on e.dept_id=d.dept_id
group by d.dept_id,d.dept_name;

-- Q4. List all departments with no employees yet.
select d.dept_name,e.emp_id
from employees as e
left join departments as d
on e.dept_id=d.dept_id
where e.emp_id is null;

/*
Q5. Add a new column gender (ENUM: 'Male', 'Female', 'Other') to the Employees table. 
Then update it for all existing records.
Q6. Get a list of departments that have more than 1 employee.
Q7. Write a query to display the youngest and oldest employees in each department.
(Hint: GROUP BY + MIN/MAX)
Q8. Create a view named active_employees_view 
that shows all employee details for those who joined after 2022.
*/

-- Q5. Add a new column gender (ENUM: 'Male', 'Female', 'Other') to the Employees table. 
-- Then update it for all existing records.

alter table employees
add column gender enum('male','female','other');
select * from employees;
update employees
set gender='male'
where emp_id=4;

-- Q6. Get a list of departments that have more than 1 employee.
select d.dept_name,count(e.emp_id) as emp_count
from departments as d
join employees as e
on d.dept_id=e.dept_id
group by dept_name,emp_id
having count(e.emp_id)>=1; -- since my table has only each 1 of emp so wrote >= in query

-- Q7. Write a query to display the youngest and oldest employees in each department.
select min(e.age)as youngest_emp,max(e.age) as oldest_emp,dept_name
from employees as e
join departments as d
on e.dept_id=d.dept_id
group by d.dept_id,d.dept_name; 

-- Q8. Create a view named active_employees_view 
-- that shows all employee details for those who joined after 2022.

create view active_employees_view as
select * from employees
where hire_date>'2022-01-01';

select * from active_employees_view;

/*
Q9. Create a Salaries table with:
salary_id (PK)
emp_id (FK)
base_salary
bonus
effective_from (DATE)
Add 2–3 salary records for each employee.
Q10. Write a stored procedure GetEmployeeSalaryDetails(empId) that returns 
full name, department, and total salary (base + bonus) for that employee.
Q11. Create a view that shows average salary per department.
Q12. Create a CTE that ranks employees within each department based on salary (highest first).
(Hint: Use RANK() or DENSE_RANK() window function)
Q13. Add an index on email column of Employees to improve lookup performance.
*/


-- Q9. Create a Salaries table with:
-- salary_id (PK)
-- emp_id (FK)
-- base_salary
-- bonus
-- effective_from (DATE)
-- Add 2–3 salary records for each employee.

create table salaries 
( salary_id varchar(10) primary key,
emp_id int,
base_salary int,
bonus float,
effective_from date,
foreign key (emp_id) references Employees(emp_id)
);

insert into salaries ( salary_id,emp_id,base_salary,bonus,effective_from)
values
('a_1',1,20000,5000,'2023-01-10'),
('a_2',2,25000,4000,'2023-07-22'),
('a_3',3,30000,3000,'2024-03-15'),
('a_4',4,25000,2000,'2023-05-12');

select * from salaries;

-- Q10. Write a stored procedure GetEmployeeSalaryDetails(empId) that returns 
-- full name, department, and total salary (base + bonus) for that employee.
delimiter //
create procedure GetEmployeeSalaryDetails(in empid int)
begin 
select concat(e.first_name,'',e.last_name) as full_name,d.dept_name,(s.base_salary+s.bonus) as total_salary
from employees as e
join departments as d
on e.dept_id= d.dept_id
join salaries as s
on e.emp_id=s.emp_id
where e. emp_id=empid;
end //
delimiter ;

call getemployeesalarydetails(2);
call getemployeesalarydetails(4);
call getemployeesalarydetails(3);
call getemployeesalarydetails(1);


-- Q11. Create a view that shows average salary per department.
create view avg_salary_per_dept as
select d.dept_name,
avg(s.base_salary+s.bonus) as avg_salary
from employees as e
join departments as d
on e.dept_id=d.dept_id
join salaries as s
on e.emp_id=s.emp_id
group by d.dept_name;

select * from avg_salary_per_dept;

-- Q12. Create a CTE that ranks employees within each department based on salary (highest first).
WITH SalaryRanking AS (
    SELECT 
        e.emp_id,
        CONCAT(e.first_name, ' ', e.last_name) AS full_name,
        d.dept_name,
        s.base_salary,
        s.bonus,
        (s.base_salary + s.bonus) AS total_salary,
        RANK() OVER (PARTITION BY e.dept_id ORDER BY (s.base_salary + s.bonus) DESC) AS salary_rank
    FROM Employees e
    JOIN Departments d ON e.dept_id = d.dept_id
    JOIN Salaries s ON e.emp_id = s.emp_id
)

SELECT * FROM SalaryRanking;

-- Q13. Add an index on email column of Employees to improve lookup performance.
create index idx_email on employees(email);

show index from employees; 