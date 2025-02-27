
-- Customer Table
create table customers0_2009(
	customerId int identity(1,1) primary key,
	customerName varchar(50) not null,
	email varchar(50) unique,
	phone varchar(10) unique not null,
	address varchar(100)
)


-- Rooms Table
create table rooms_2009(
	roomId int identity(1,1) primary key,
	roomType varchar(10) check (roomType in ('AC', 'Non-AC')),
	pricePerNight int not null check (pricePerNight >= 0),
	status varchar(10) check (status in ('available', 'occupied')) not null,
)




-- Bookings Table
create table bookings0_2009(
	bookingId int identity(1,1) primary key,
	customerId int foreign key references customers0_2009(customerId) not null,
	roomId int foreign key references rooms_2009(roomId) not null,
	checkInDate date,
	checkOutDate date,
	totalAmount int not null check(totalAmount >= 0)
)



-- Payments Table
create table payments_2009(
	paymentId int identity(1,1) primary key,
	bookingId int foreign key references bookings0_2009(bookingId) not null,
	paymentDate date,
	amount int not null check(amount >= 0),
	paymentMethod varchar(20) check (paymentMethod in ('online', 'cash'))
)


-- Employees Table
create table employees_2009(
	employeeId int identity(1,1) primary key,
	employeeName varchar(50) not null,
	position varchar(30),
	salary int not null check(salary >= 0),
	hireDate date not null,
	managerId int foreign key references employees_2009(employeeId)
)



-- Services Table
create table services_2009(
	serviceId int identity(1,1) primary key,
	serviceName varchar(50) not null,
	price int check (price >= 0)
)


-- Booking Service Table
create table bookingService_2009(
	bookingId int foreign key references bookings_2009(bookingId),
	serviceId int foreign key references services_2009(serviceId),
	quantity smallint check (quantity >= 0),
	totalServiceCost int check (totalServiceCost >= 0)
)

--insert into bookingService_2009 values(1, 1, 2, 400);
insert into bookingService_2009 values(2, 2, 1, 500);

-- Hotel Branch Table
create table hotelBranch_2009(
	branchId int identity(1,1) primary key,
	branchName varchar(50) not null,
	location varchar(30) not null,
)
--alter table hotelBranch_2009 add description varchar(100);
insert into hotelBranch_2009 values('branch 2', 'mumbai', 'Luxurious hotel with a great sea view along the coasts of mumbai.');

-- 1. DML Queries

insert into customers0_2009 values('customer 1', 'cust1@email.com', '9846271340', 'address 1');
insert into customers0_2009 values('customer 2', 'cust2@email.com', '8046271312', 'address 2');
insert into customers0_2009 values('customer 3', 'cust3@email.com', '8546271374', 'address 3');
insert into customers0_2009 values('customer 4', 'cust4@email.com', '9246271536', 'address 4');

insert into rooms_2009 values('AC', 4000, 'available');
insert into rooms_2009 values('Non-AC', 3000, 'available');
insert into rooms_2009 values('AC', 4000, 'available');
insert into rooms_2009 values('Non-ac', 3000, 'available');
insert into rooms_2009 values('AC', 4000, 'occupied');

insert into bookings0_2009 values(1, 6, getdate(), '2025-02-28', 4000);
insert into bookings0_2009 values(1, 6, getdate(), '2025-02-28', 4000);

insert into payments_2009 values(1, '2025-02-28', 4000, 'online');
insert into payments_2009 values(2, '2025-03-28', 3000, 'online');
insert into payments_2009 values(2, '2025-03-28', 4000, 'cash');

insert into employees_2009 values('employee 1', 'accountact', 30000, '2020-01-01', 2);
insert into employees_2009 values('employee 2', 'manager', 40000, '2018-02-02', null);
insert into employees_2009 values('employee 3', 'chef', 35000, '2029-03-03', 2);

insert into services_2009 values('laundry',300);
insert into services_2009 values('parking',100);
insert into services_2009 values('wifi',500);


-- 2. Queries using join
select customerName, roomType, checkInDate, totalAmount
from customers0_2009 join bookings0_2009 on customers0_2009.customerId = bookings0_2009.customerId join 
rooms_2009 on bookings0_2009.roomId = rooms_2009.roomId; 

select e2.employeeName as 'employee',e2.salary, e2.hiredate, e2.position, e1.employeeName as 'manager'
from employees_2009 as e1 join employees_2009 as e2 on e1.employeeId = e2.managerId;

select distinct rooms_2009.roomId, roomType, pricePerNight, status
from rooms_2009 join bookings0_2009 on rooms_2009.roomId != bookings0_2009.roomId;


-- 3. Subqueries
select *
from customers0_2009 
where customerId in (
	select customerId
	from bookings0_2009
	group by customerId
	having count(customerId) > 1
)

select *
from rooms_2009
where roomId in (
	select roomId
	from bookings0_2009
	where totalAmount = (select max(totalAmount) from bookings0_2009)
)

-- 4. Views
GO
create view activeBookings as 
select customerName, roomType, checkInDate, totalAmount
from customers0_2009 join bookings0_2009 on customers0_2009.customerId = bookings0_2009.customerId join 
rooms_2009 on bookings0_2009.roomId = rooms_2009.roomId; 

GO
select * from activeBookings;


-- 5. Index
create index roomTypeIndex on rooms_2009(roomType);

create index dateIndex on bookings0_2009(checkInDate, checkOutDate);


-- 6. Procedure and Function
GO
create procedure getRevenueOfMonth @month varchar(15), @totalRevenue int output
as 
begin
	set @totalRevenue = (select sum(amount) from payments_2009 group by DATENAME(month, paymentDate) having DATENAME(month, paymentDate) = @month);
end

GO
declare @calculatedTotalRevenue int;
exec getRevenueOfMonth @month='march', @totalRevenue = @calculatedTotalRevenue OUTPUT;
print(concat('Total revenue = ', @calculatedTotalRevenue));

GO
create function findCustomerTotalVisitDays(@customerId int)
returns int
as 
begin
	return (select sum(datediff(day, checkInDate, checkOutDate)) from bookings0_2009 where customerId = @customerId);
end

GO
print(dbo.findCustomerTotalVisitDays(1))


-- 7. Trigger
-- Cancel booking trigger
GO
create trigger updateRoomStatus on bookings0_2009
instead of delete
as
begin
	update rooms_2009 set status = 'available' where roomId in (select roomId from deleted);
	delete from bookingService_2009 where bookingId in (select bookingId from deleted);
end


delete from bookings0_2009 where bookingId = 1;
update rooms_2009 set status = 'occupied' where roomId = 6;

-- drop trigger updateRoomStatus;

-- After booking trigger
GO
create trigger updateRoomStatusAfterBooking on bookings0_2009
after insert
as
begin
	update rooms_2009 set status = 'occupied' where roomId in (select roomId from inserted);
end

insert into bookings0_2009 values(2, 1, getdate(), '2025-02-28', 3000);
update rooms_2009 set status = 'available' where roomId = 1;


-- Service Trigger
-- Reduce amount after removing service
GO
create trigger updateAmountAfterServiceDelete on bookingService_2009
after delete
as
begin
	update bookings0_2009 set totalAmount -= (select totalServiceCost from deleted) where bookingId in (select bookingId from deleted);
end

delete from bookingService_2009 where bookingId = 1;


-- Increase amount after adding service
GO
create trigger updateAmountAfterServiceAdded on bookingService_2009
after insert
as
begin
	update bookings0_2009 set totalAmount += (select totalServiceCost from inserted) where bookingId in (select bookingId from inserted);
end

insert into bookingService_2009 values(1, 1, 2, 400);


--drop trigger updateAmountAfterServiceDelete;

-- 8. Security

create role hotelManager_2009;
grant select, update to hotelManager_2009;

create role frontDeskStaff_2009;
grant select on rooms_2009 to frontDeskStaff_2009;

-- 9. Backup and Recovery

-- backup database hotelDatabase
-- to disk = ''
-- with format, name = 'hotel database backup';

-- restore database hotelDatabase
-- from disk = ''
-- with recovery;


-- 10. Full Text Search
CREATE UNIQUE INDEX hotelBranchIndex on hotelBranch_2009(branchId);

create fulltext index on hotelBranch_2009(description, location) 
key index hotelBranchIndex;

select * from hotelBranch_2009 where contains(description, '"sea view"');





select * from customers0_2009;
select * from rooms_2009;
select * from bookings0_2009;
select * from payments_2009;
select * from employees_2009;
select * from services_2009;
select * from bookingService_2009;
select * from bookings0_2009;
