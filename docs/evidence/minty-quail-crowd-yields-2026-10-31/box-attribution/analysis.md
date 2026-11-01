base runs 48, head runs 48

### BASE: 48 runs, box_stalls 25, sum of longest box stands 323s

Seconds a car stood inside a box (speed under 1 px/s), by what the root of its queue stood for (total 1193s):
| root cause | seconds | share |
|---|---|---|
| box_or_signal | 721.9 | 60.5% |
| gate | 215.8 | 18.1% |
| car_unknown | 148.9 | 12.5% |
| zebra | 65.3 | 5.5% |
| car_moving | 39.6 | 3.3% |
| other | 0.7 | 0.1% |
| closed_tile | 0.7 | 0.1% |
| turning | 0.0 | 0.0% |

Of which figure, by row and the figure's state:
| row | state | seconds |
|---|---|---|

Seconds in a box with a figure within 120 px ahead in the lane (geometry, regardless of cause):
| row | state | seconds |
|---|---|---|
| checkpoint_gate | standing | 138.7 |
| unmapped | standing | 76.4 |
| unmapped | moving | 0.3 |
| checkpoint_gate | moving | 0.1 |
| police_patrol | moving | 0.0 |

Direct flags (what the car's own brake components say; '+' joins several):
| flags | seconds |
|---|---|
| car | 911.3 |
| gate | 215.8 |
| zebra | 64.3 |
| other | 0.7 |
| closed_tile | 0.7 |
| turning | 0.0 |

Stands of 0.5 s or more: 303
- 0.5-1s: 33
- 1-2s: 208
- 2-5s: 37
- 5-10s: 5
- 10-30s: 7
- 30-100s: 13

Stalls (stand of 5 s or more), dominant root cause of each (more than half of its ticks), figure row and state:
| seed | day | walk | seconds | dominant root | row | state | figure share of ticks | figure in view at box entry |
|---|---|---|---|---|---|---|---|---|
| 1001 | 1 | walkers | 5.3 | zebra |  |  | 0% | unmapped:standing |
| 2222 | 1 | road | 60.0 | car_unknown |  |  | 0% | no |
| 2222 | 1 | road | 50.9 | box_or_signal |  |  | 0% | no |
| 2222 | 1 | road | 18.8 | box_or_signal |  |  | 0% | no |
| 2222 | 1 | road | 7.9 | box_or_signal |  |  | 0% | no |
| 2222 | 1 | walkers | 5.2 | box_or_signal |  |  | 0% | no |
| 3003 | 1 | road | 26.3 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 53.2 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 52.2 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 33.8 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 31.1 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 18.6 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | walkers | 13.2 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | walkers | 8.7 | box_or_signal |  |  | 0% | no |
| 6006 | 1 | walkers | 9.4 | box_or_signal |  |  | 0% | no |
| 6006 | 1 | walkers | 22.6 | car_unknown |  |  | 0% | no |
| 6006 | 1 | walkers | 20.5 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 60.0 | car_unknown |  |  | 0% | no |
| 8008 | 1 | road | 53.9 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 48.0 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 47.0 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 46.6 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 41.6 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 39.6 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 16.8 | box_or_signal |  |  | 0% | no |

Stands with 1.0 s or more of figure root cause: 
| seed | day | walk | stand s | figure s | row:state | figure in view at box entry | ticks in box before standing |
|---|---|---|---|---|---|---|---|

### HEAD: 48 runs, box_stalls 38, sum of longest box stands 381s

Seconds a car stood inside a box (speed under 1 px/s), by what the root of its queue stood for (total 1396s):
| root cause | seconds | share |
|---|---|---|
| box_or_signal | 889.4 | 63.7% |
| gate | 200.0 | 14.3% |
| car_unknown | 147.3 | 10.6% |
| figure | 57.9 | 4.1% |
| zebra | 56.3 | 4.0% |
| car_moving | 44.5 | 3.2% |
| other | 0.5 | 0.0% |
| closed_tile | 0.0 | 0.0% |

Of which figure, by row and the figure's state:
| row | state | seconds |
|---|---|---|
| dog_walker | moving | 26.7 |
| homeless_yeller | moving | 26.5 |
| police_patrol | moving | 1.6 |
| loose_dog | moving | 1.1 |
| none_found |  | 0.9 |
| chatting_mother | moving | 0.8 |
| cat_dash | moving | 0.1 |
| roadblock | standing | 0.1 |

Seconds in a box with a figure within 120 px ahead in the lane (geometry, regardless of cause):
| row | state | seconds |
|---|---|---|
| checkpoint_gate | parked | 189.4 |
| homeless_yeller | moving | 33.9 |
| dog_walker | moving | 26.8 |
| police_patrol | moving | 1.6 |
| loose_dog | moving | 1.2 |
| chatting_mother | moving | 0.8 |
| cat_dash | moving | 0.1 |
| roadblock | standing | 0.1 |

Direct flags (what the car's own brake components say; '+' joins several):
| flags | seconds |
|---|---|
| car | 1083.0 |
| gate | 200.0 |
| figure | 56.8 |
| zebra | 55.3 |
| other | 0.5 |
| figure+zebra | 0.3 |
| closed_tile | 0.0 |

Stands of 0.5 s or more: 347
- 0.5-1s: 51
- 1-2s: 222
- 2-5s: 36
- 5-10s: 12
- 10-30s: 11
- 30-100s: 15

Stalls (stand of 5 s or more), dominant root cause of each (more than half of its ticks), figure row and state:
| seed | day | walk | seconds | dominant root | row | state | figure share of ticks | figure in view at box entry |
|---|---|---|---|---|---|---|---|---|
| 1001 | 1 | road | 5.2 | box_or_signal |  |  | 0% | no |
| 1001 | 1 | road | 5.2 | box_or_signal |  |  | 0% | no |
| 1001 | 1 | road | 10.6 | box_or_signal |  |  | 0% | no |
| 1001 | 1 | road | 5.4 | box_or_signal |  |  | 0% | no |
| 1001 | 1 | walkers | 5.3 | zebra |  |  | 0% | no |
| 1001 | 9 | road | 12.0 | box_or_signal |  |  | 0% | no |
| 2222 | 1 | road | 60.0 | car_unknown |  |  | 0% | no |
| 2222 | 1 | road | 50.9 | box_or_signal |  |  | 0% | no |
| 2222 | 1 | road | 18.8 | box_or_signal |  |  | 0% | no |
| 2222 | 1 | road | 7.8 | box_or_signal |  |  | 0% | no |
| 3003 | 1 | road | 5.4 | box_or_signal |  |  | 0% | no |
| 3003 | 1 | road | 40.9 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 52.4 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 50.5 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 38.2 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 37.0 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 34.1 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 25.4 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 24.7 | car_unknown |  |  | 0% | no |
| 4242 | 1 | road | 18.6 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 11.7 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 9.7 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | road | 7.4 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | walkers | 13.0 | box_or_signal |  |  | 0% | no |
| 4242 | 1 | walkers | 8.7 | box_or_signal |  |  | 0% | no |
| 6006 | 1 | walkers | 23.9 | box_or_signal |  |  | 0% | no |
| 7007 | 9 | road | 5.3 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 60.0 | car_unknown |  |  | 0% | no |
| 8008 | 1 | road | 53.9 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 48.0 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 47.0 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 41.6 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 39.6 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 32.0 | box_or_signal |  |  | 0% | no |
| 8008 | 1 | road | 8.8 | box_or_signal |  |  | 0% | no |
| 9009 | 1 | walkers | 14.9 | box_or_signal |  |  | 0% | no |
| 478156010 | 1 | walkers | 12.9 | box_or_signal |  |  | 0% | no |
| 478156010 | 1 | walkers | 6.8 | box_or_signal |  |  | 0% | no |

Stands with 1.0 s or more of figure root cause: 
| seed | day | walk | stand s | figure s | row:state | figure in view at box entry | ticks in box before standing |
|---|---|---|---|---|---|---|---|
| 1001 | 1 | road | 1.1 | 1.1 | {'dog_walker:moving': 33} | no | 0.8 |
| 1001 | 1 | road | 1.6 | 1.6 | {'homeless_yeller:moving': 47} | no | 0.4 |
| 1111 | 1 | road | 1.3 | 1.3 | {'homeless_yeller:moving': 39} | no | 0.7 |
| 1111 | 1 | road | 1.6 | 1.6 | {'homeless_yeller:moving': 47} | no | 1.2 |
| 1111 | 1 | walkers | 1.2 | 1.2 | {'homeless_yeller:moving': 35} | homeless_yeller:moving | 0.1 |
| 1111 | 1 | walkers | 1.4 | 1.4 | {'homeless_yeller:moving': 43} | no | 0.8 |
| 1111 | 1 | walkers | 1.8 | 1.8 | {'homeless_yeller:moving': 52, 'none_found:': 1} | no | 0.5 |
| 2002 | 1 | walkers | 1.5 | 1.5 | {'dog_walker:moving': 45} | no | 0.7 |
| 2002 | 1 | walkers | 1.1 | 1.1 | {'dog_walker:moving': 33} | dog_walker:moving | 0.0 |
| 2222 | 1 | road | 1.9 | 1.9 | {'homeless_yeller:moving': 52, 'none_found:': 4} | no | 1.5 |
| 2222 | 1 | road | 1.7 | 1.7 | {'homeless_yeller:moving': 52} | no | 0.6 |
| 2222 | 1 | walkers | 1.7 | 1.7 | {'homeless_yeller:moving': 52} | no | 0.6 |
| 2222 | 1 | walkers | 1.8 | 1.8 | {'dog_walker:moving': 47, 'none_found:': 6} | no | 1.7 |
| 3003 | 1 | road | 1.7 | 1.7 | {'dog_walker:moving': 47, 'none_found:': 3} | no | 0.3 |
| 3003 | 1 | walkers | 1.7 | 1.7 | {'dog_walker:moving': 47, 'none_found:': 3} | no | 0.3 |
| 3003 | 1 | walkers | 1.6 | 1.6 | {'homeless_yeller:moving': 48} | no | 0.3 |
| 3003 | 1 | walkers | 1.5 | 1.5 | {'dog_walker:moving': 45} | no | 1.4 |
| 3003 | 9 | road | 1.0 | 1.0 | {'dog_walker:moving': 30} | dog_walker:moving | 0.1 |
| 3003 | 9 | road | 1.5 | 1.5 | {'dog_walker:moving': 44} | no | 1.3 |
| 3003 | 9 | walkers | 1.4 | 1.4 | {'homeless_yeller:moving': 43} | no | 0.8 |
| 3003 | 9 | walkers | 1.8 | 1.8 | {'homeless_yeller:moving': 52, 'none_found:': 1} | no | 2.6 |
| 4242 | 9 | walkers | 1.3 | 1.3 | {'dog_walker:moving': 38} | roadblock:standing | 2.1 |
| 5005 | 1 | road | 1.5 | 1.5 | {'dog_walker:moving': 46} | no | 0.5 |
| 6006 | 1 | road | 1.8 | 1.8 | {'homeless_yeller:moving': 52, 'none_found:': 3} | no | 0.4 |
| 6006 | 9 | road | 1.1 | 1.1 | {'homeless_yeller:moving': 33} | no | 0.8 |
| 6006 | 9 | walkers | 1.1 | 1.1 | {'homeless_yeller:moving': 34} | no | 0.8 |
| 7007 | 9 | road | 1.0 | 1.0 | {'police_patrol:moving': 28, 'roadblock:standing': 2} | no | 27.5 |
| 7007 | 9 | walkers | 1.0 | 1.0 | {'dog_walker:moving': 30} | police_patrol:moving | 1.3 |
| 7007 | 9 | walkers | 1.1 | 1.1 | {'dog_walker:moving': 32} | no | 0.8 |
| 8008 | 1 | walkers | 1.8 | 1.8 | {'dog_walker:moving': 47, 'none_found:': 6} | no | 1.0 |
| 8008 | 1 | walkers | 1.6 | 1.6 | {'homeless_yeller:moving': 49} | no | 1.4 |
| 478156010 | 1 | walkers | 1.4 | 1.4 | {'dog_walker:moving': 43} | no | 0.3 |

base: stands with any figure-rooted ticks: figure seconds none; whole-stand seconds none

head: stands with any figure-rooted ticks: figure seconds n=45 median 1.3s p90 1.8s max 1.9s; whole-stand seconds n=45 median 1.3s p90 1.8s max 2.1s

Stalls per pair, base vs head (stall = a stand of 5 s or more):
| seed | day | walk | base stalls | head stalls | base longest | head longest |
|---|---|---|---|---|---|---|
| 1001 | 1 | road | 0 | 4 | 0.1 | 10.6 |
| 1001 | 9 | road | 0 | 1 | 1.2 | 12.0 |
| 2002 | 1 | road | 0 | 0 | 1.6 | 4.0 |
| 2222 | 1 | walkers | 1 | 0 | 5.2 | 3.5 |
| 3003 | 1 | road | 1 | 2 | 26.3 | 40.9 |
| 4242 | 1 | road | 5 | 11 | 53.2 | 52.4 |
| 5005 | 1 | walkers | 0 | 0 | 4.7 | 1.1 |
| 6006 | 1 | walkers | 3 | 1 | 22.6 | 23.9 |
| 6006 | 9 | walkers | 0 | 0 | 4.6 | 1.2 |
| 7007 | 9 | road | 0 | 1 | 4.7 | 5.3 |
| 9009 | 1 | walkers | 0 | 1 | 4.5 | 14.9 |
| 478156010 | 1 | walkers | 0 | 2 | 3.2 | 12.9 |

stalls base 25 head 38
base: stands of 150 ticks or more in the attribution 25; probe's box_stalls 25
head: stands of 150 ticks or more in the attribution 38; probe's box_stalls 38
