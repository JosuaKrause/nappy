# Playtest downy-egret — Scene composition review: distinct streets, fixture control and gate approach

2026-10-03.

The player reviews the ten images embedded in PR #457 at
`ee39fd776fbc84dbc40e80dee03a83620b2ed13d`, in their displayed order:
1 and 2 are the power-station hall and fenced-yard joins; 3 is the wrong-way choice;
4 is the father and leaf blower; 5 is the charging dog; 6 is the title over the city;
7 is the army trucks; 8 is the gatehouse; 9 is the carrying chase; 10 is the full city.
The preview describes number 8 as a horizontal gate and shows the father approaching
along a north–south street. The player corrects the relationship between his approach
and the gate itself, and says:

> regarding 457. 1)2) power plant edge cases look good 3) player is stuck against restaurant guests -- maybe move them one block to the right. also the right side has significantly fewer pedestrians 4) this is the same scene as 3) just the player is on the other side of the street we cannot use that 5) what is the water main break doing there? 6) all four city examples so far have the exact same building just the events are different. can you place roof fixtures manually? 7) remove the barrier at the bottom -- move it to the left street instead of the other bollards (vertical) 8) horizontal approach to the gate means the gate itself is vertical

The assistant identifies that recipes currently pin a building layout seed rather than
individual roof-fixture positions, and proposes adding that control for deliberately
different early scenes. The assistant interprets "move them" as moving the restaurant
guests one block east and asks whether the player instead means moving the player/action.
That clarification remains pending at filing; independent scene corrections can proceed.
