rm(list = ls())
library(dplyr)
library(tidyr)
library(ggplot2)
library(wesanderson)
# library(gghalves)
# library(ggdist)


color =  c("#FFC900", "#086E7D", "#FF5959")
YG = c("#00A19D", "#FFB344", "#E05D5D")
YB = c('#FFC000', '#0740A7')
YB = c("#00A19D", "#FFB344", "#E05D5D")
YB2= c("#FFa200", "#24a8ac")
RB = c('#ef8a62','#67a9cf' )


mycurve = list(
  stat_summary(geom = "point", fun = "mean", size = 3),
  stat_summary(geom = "errorbar", position = position_dodge(0.7),  fun.data = "mean_cl_boot", width = 0.1, size = 0.5),
  stat_summary(geom = 'line', fun = 'mean', size = 1),
  scale_color_manual(values = YB2),  
  theme_gray(),
  theme(strip.text.x = element_text(size = 14, color = "black", face = "bold"), 
        strip.text.y = element_text(size = 14, color = "black", face = "bold"),
        strip.background = element_blank(),
        panel.background = element_rect(fill = 'grey95',color = 'white'),
        panel.grid.major.x = element_line(linetype = 'solid', color='grey85'),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(linetype = 'solid',color='grey85'),
        panel.grid.minor.y = element_line(linetype = 'solid',color='grey90'),
        plot.title = element_text(hjust = 0.5, size = 18, color = "black",face = "bold"), 
        axis.title.x = element_text(size = 12, color = "black", face = "plain"),
        axis.title.y = element_text(size = 14, color = "black", face = "bold"), 
        axis.text.x = element_text(size = 12, color = "black", face = "bold"), 
        axis.text.y = element_text(size = 12, color = "black"),
        legend.text = element_text(size = 12, face = "bold"),legend.title = element_blank(),legend.position = "right", strip.placement = "outside",
  )
)



mybar.1way = list(
  stat_summary(geom = "bar", fun = "mean", position = position_dodge(width = 0.9),width = 0.7, color = 'grey20'),
  geom_line(aes(group = Subject),position = position_dodge(0), color = 'grey70', linetype = 'dotted'),
  stat_summary(geom = "errorbar", position = position_dodge(0.9),  fun.data = "mean_cl_boot", color = 'grey20', width = 0.3, size = 1),
  geom_point(aes(group = Condi), position = position_dodge(0.9), color = 'grey30', fill = 'grey30', alpha = 1),
  theme_gray(), scale_fill_manual(values = RB), 
  geom_hline(yintercept = 0, size = 2),
  theme(strip.text.x = element_text(size = 13, color = "black", face = "bold"), 
        strip.text.y = element_text(size = 13, color = "black", face = "bold"),
        strip.background = element_blank(),
        panel.background = element_rect(color = 'grey90', fill = 'grey90'),
        panel.spacing = unit(1, "lines"),
        # panel.grid.minor.x = element_blank(),
        # panel.grid.major.x =  element_line(linetype = 'solid',color='white'),
        # panel.grid.minor.y = element_blank(),
        # panel.grid.major.y = element_line(linetype = 'solid',color='white'),
         plot.title = element_text(hjust = 0.5, size = 14, color = "black",face = "bold"), 
        axis.title.x = element_blank(), 
        axis.text.x = element_text(size = 12, color = "black", face = "bold"), 
        axis.title.y = element_text(size = 12, color = "black", face = "bold"), 
        axis.text.y = element_text(size = 10, color = "black"),
        legend.position = "none",
  )
)


## --------------
dataFolder = 'C:\\Projects\\BiologicalMotion\\Codes\\flah lag'
setwd(dataFolder)
D= read.csv(file = 'PSEdata.csv')
D = D %>% 
 mutate(x = case_when(Condi%%2==1~'Condi1', Condi%%2 == 0 ~ 'Condi2'))
D$Exp = factor(D$Exp)
levels(D$Exp)
D$Exp=factor(D$Exp, levels = c('Biological Motion', 'Static', 'Feet', 'Feet: Normal vs Reversed', 'Car', 'Static Photos'))

D$Condi = as.factor(D$Condi)


limits = c( max(D$R), 1.15 *min(D$R))

thisgroup = D %>% 
  filter(Exp=='Biological Motion')



ggplot(thisgroup, aes(x = Condi, y = R,fill = Condi)) +
  ggdist::stat_halfeye(
    ## custom bandwidth
    adjust = 1, 
    ## adjust height
    width = .5, 
    ## move geom to the right
    justification = -.2, 
    ## remove slab interval
    .width =  c(.5, .95), 
    point_colour = NA
  )+
geom_boxplot(
  width = .12, 
  outlier.shape = NA)+ 

## add justified jitter from the {gghalves} package
gghalves::geom_half_point(
  ## draw jitter on the left
  side = "l", 
  ## control range of jitter
  range_scale = .0, 
  ## add some transparency
  alpha = .3
)+
  scale_y_reverse(breaks = seq(-1, 1, by = 0.02), minor_breaks = seq(-1.02, 1, 0.01), limits =limits) 
  





dev.off()
plot1 = D  %>% 
  ggplot(aes(x = x, y = R, fill = x)) + 
  mybar.1way + 
  facet_wrap(vars(Exp), scales = "free_x",  nrow = 1) +
  scale_y_reverse(breaks = seq(-1, 1, by = 0.02), minor_breaks = seq(-1.02, 1, 0.01), limits =limits) +
  labs(y = "Point of Subjective Equality (Degree)") +
  scale_x_discrete(labels = c("Upright","Inverted")) 
plot(plot1)



ggsave("myplot.eps",plot1)




