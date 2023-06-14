
/*
Below is a procedure to create a table with total calculated bonus as per user
we can filter data as per date and time 
*/

CREATE PROCEDURE calculate_loyalty_bonus
@start_date datetime,
@end_date datetime
AS
begin 
set NOCOUNT on;

---- filter required data according to date and time 

;with Deposit_Data1 as ( SELECT * from Deposit_Data where datetime BETWEEN @start_date and @end_date),

Withdrawal_Data1 as ( SELECT * from Withdrawal_Data where datetime BETWEEN @start_date and @end_date),

User_Gameplay_data1 as ( SELECT * from User_Gameplay_data where datetime BETWEEN @start_date and @end_date),

---  deposit bouns calculation

d_bonus as 
(SELECT *, (amount * 0.01) as Deposite_bonus FROM Deposit_Data1),

Deposite_bonus_table as 
(SELECT user_id, sum(Deposite_bonus) as Deposite_bonus, count(user_id) as no_of_Deposit FROM d_bonus
GROUP by user_id),


--- Withdrawal_Data bonus calculation  

w_bonus as 
(SELECT *, (amount * 0.005) as Withdrawal_bonus FROM Withdrawal_Data1),

Withdrawal_bonus_table as 
(SELECT user_id, sum(Withdrawal_bonus) as Withdrawal_bonus, count(user_id) as no_of_Withdrawal FROM w_bonus
GROUP by user_id),

--- difference bettween no of deposite and Withdrawal bonus calculation

difference_bonus_table as 
(SELECT d.user_id, Deposite_bonus, Withdrawal_bonus,
case when (no_of_Deposit - no_of_Withdrawal) > 0 then (no_of_Deposit - no_of_Withdrawal) * 0.001 else 0 end as difference_bonus
FROM Deposite_bonus_table as d Inner JOIN 
Withdrawal_bonus_table as w on 
d.user_id = w.user_id),

----- No of Games played bonus calculationdemo

Games_played_bonus as 
(SELECT user_id, total_games_played, (total_games_played * 0.2) as Games_played_bonus from(
SELECT user_id, sum(games_played) as total_games_played 
FROM User_Gameplay_data1
GROUP by user_id) as abc),

---- Total bonus table

Total_bonus_table as 
(SELECT *, (COALESCE(Games_played_bonus,0) + COALESCE(Deposite_bonus,0) 
 + COALESCE(Withdrawal_bonus,0) + COALESCE(difference_bonus,0)) as Total_bonus from
(SELECT d.user_id, total_games_played, Games_played_bonus, t.Deposite_bonus, w.Withdrawal_bonus, difference_bonus
from Games_played_bonus as d 
Left join difference_bonus_table as g 
on d.user_id = g.user_id left join Withdrawal_bonus_table as w 
on d.user_id = w.user_id left join Deposite_bonus_table as t
on d.user_id = t.user_id) as axc)

SELECT * from Total_bonus_table;

end;

/*
1. Find Playerwise Loyalty points earned by Players in the following slots:-
    a. 2nd October Slot S1
    b. 16th October Slot S2
    b. 18th October Slot S1
    b. 26th October Slot S2

*/

EXEC calculate_loyalty_bonus @start_date = '2022-10-02 00:00:00', @end_date = '2022-10-02 12:00:00';
EXEC calculate_loyalty_bonus @start_date = '2022-10-16 12:00:01', @end_date = '2022-10-16 23:59:59';
EXEC calculate_loyalty_bonus @start_date = '2022-10-18 00:00:00', @end_date = '2022-10-18 12:00:00';
EXEC calculate_loyalty_bonus @start_date = '2022-10-26 12:00:01', @end_date = '2022-10-26 23:59:59';



/*
2. Calculate overall loyalty points earned and rank players on the basis of loyalty points in the month of October. 
     In case of tie, number of games played should be taken as the next criteria for ranking.
*/

CREATE TABLE Total_bonus (
  user_id integer,
  total_games_played integer,
  Games_played_bonus integer,
  Deposite_bonus integer,
  Withdrawal_bonus integer,
  difference_bonus integer,
  Total_bonus integer
  );


---- PART A Que 2 ( start_date 2022-10-02 00:00:00 and end_date = 2022-10-31 23:59:59 (october month))


INSERT INTO Total_bonus
	EXEC calculate_loyalty_bonus @start_date = '2022-10-02 00:00:00', @end_date = '2022-10-31 23:59:59';

create view ranking_table as SELECT user_id, Total_bonus, total_games_played, row_number() over 
(ORDER BY Total_bonus DESC, total_games_played DESC) as rank from Total_bonus;

--- Ranking in a specific month ( Answer PART A Que 2 )

SELECT * FROM ranking_table;


/*
3. What is the average deposit amount?
*/
SELECT avg(amount) as avg_amount from Deposit_Data;


/*
4. What is the average deposit amount per user in a month?
*/
SELECT month(datetime) as month, avg(amount) as avg_monthly from Deposit_Data
GROUP by month(datetime);


/*
5. What is the average number of games played per user?
*/
SELECT user_id, avg(games_played) FROM User_Gameplay_data
GROUP by user_id;


----- PART B 
----- 5000 rs pool distribution ( Divided 5000 among top 50 users 
/*

Divided 5000 among top 50 users
The rank is givin on the basis of loyalty bonus 
Rank 1 - 800
Rank 2 - 400
Rank 3 - 300
Rank 4,5 - 250
Rank 5 to 10 - 150
Rank 11 to 30 - 75
Rank 31 to 40 - 50
Rank 41 to 50 - 25

*/

SELECT user_id, rank,
case when rank = 1 then 800
when rank = 2 then 400
when rank = 3 then 300
when rank in (4,5) then 250
when rank > 5 and rank < 11 then 150
when rank > 10 and rank < 31 then 75
when rank > 30 and rank < 41 then 50
when rank > 40 and rank <= 50 then 25 end as Loyalty_bonus_prize
from ranking_table
WHERE rank <= 50;
