%function returns true if the agent is being an obstacle 
%on the way of the ball to the opponent's goal. Main program tells the agent to clear. 
function onTheWay = isOnTheWay(aIndex, TeamOwn, Ball)

global  FieldY Environment
onTheWay = 0;
%Received parameters
Bx=Ball.Pos(1);
By=Ball.Pos(2);
Vx=Ball.Pos(3);
Vy=Ball.Pos(4);
if Vx > 0
    if Vx || Vy ~= 0
        slope = Vy/Vx;

        %x=150 - side coordinate under attack
        ua = slope*(150 - Bx) + By;
        %x=Agent.pos(x) - if agent is on the way
        ow = slope * (TeamOwn{aIndex}.Pos(1) - Bx) + By;


        if ua < FieldY/2+Environment.GoalSize/2 && ua > FieldY/2-Environment.GoalSize/2
            %if ball is aimed at the goal check the agent's location
            if TeamOwn{aIndex}.Pos(2) < ow + 3 && TeamOwn{aIndex}.Pos(2) < ow - 3
                onTheWay = 1;
            end
        end
    end
end