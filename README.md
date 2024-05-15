# Biological-Motion---FLE

## Data: 
PSE-results-all-exp.mat contains the PSEs of all the six experiments. Plotting can be made using plotting.R

## Scripts:
Exp 1: flash_lag_BM_static.m (should change usestatic=0 to show dynamic stimuli)
Exp 2: flash_lag_BM_static.m (should change usestatic=1 to show static stimuli)
Exp 3: flash_lag_initialversion.m (this script contains 6 blocks, of which blocks 1-4 are unused previous versions of the experiment, so that only block 5 and 6 are for feet)
Exp 4: flash_lag_feet_norm_inverse.m 
Exp 5: flash_lag_Car.m (the script tested two versions of the car. The first version was the original car, the second version was modified to be symmetrical for avoiding the tilt repulsion effect explained in supplementary material. The second version was the one reported in Exp 5.
Exp 6: flash_lag_implied_motion_2.m 

## Stimuli: 
in actions.zip folder (unzip it first). 
Exp 1, 2, 3, 4: /Walk_Front_60.mat
Exp 5: /car/car_revised
Exp 6: /IM-with-fixation and /noIM-with-fixation.
When you run the experiment scripts, it should load corresponding stimuli from actions folder.

## Demos:
in MovieDemos folder
