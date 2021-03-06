library(RColorBrewer)
library(classInt)
library(dplyr)
library(stringr)
library(ggplot2)
library(scales)
library(maptools)
library(sp)
#### Load cleaned data with geocoord ####
setwd("C:/Users/Client/Desktop/kijiji_map")
kijiji_df<- read.csv("kijiji.csv",sep=";",stringsAsFactors = FALSE)
kijiji_df$lon <- as.numeric(kijiji_df$lon)
kijiji_df$lat <- as.numeric(kijiji_df$lat)
kijiji_df$room[kijiji_df$room=="b-appartement-condo-3-1-2"] <- "3 et demi"
kijiji_df$room[kijiji_df$room=="b-appartement-condo-4-1-2"] <- "4 et demi"
kijiji_df$room[kijiji_df$room=="b-appartement-condo-5-1-2"] <- "5 et demi"
kijiji_df$room[kijiji_df$room=="b-appartement-condo-6-1-2-et-plus"] <- "6 et demi ou plus"

## Spatial join
area <- readShapePoly("QUARTIER/QUARTIER.shp")

kijiji_df <- kijiji_df[!is.na(kijiji_df$lon),]
coordinates(kijiji_df) <- ~lon+lat 
proj4string(kijiji_df) <- proj4string(area)
joined <- over(kijiji_df, area)
kijiji_df <- cbind.data.frame(kijiji_df,joined)
kijiji_df <- kijiji_df[!is.na(kijiji_df$NOM),] # keep only those in Quebec city

#### Price/number of rooms ####
p_median <- kijiji_df %>% group_by(room)%>%
  summarise(med=median(price),no=n())

png(filename="C:/Users/Client/Desktop/price-rooms.png",
    type="cairo",
    units="in",
    width=5*2, 
    height=4*2, 
    pointsize=12*2,
    res=96)
ggplot(kijiji_df, aes(x=room, y=price)) + 
  geom_boxplot(fill='#A4A4A4', color="black")+
  scale_y_continuous(labels=dollar_format(prefix="$"))+
  geom_text(data = p_median, aes(x = room, y = med,
                                 label = paste("$",med)), 
            size = 3, vjust = -1)+
  labs(x="",y="",title="Prix des loyers selon le nombre de pièces")
dev.off()
#### Density/ area ####
district_stat<- kijiji_df %>% group_by(NOM)%>% 
  summarize(median_price= median(price),
            sd_price=sd(price),number=n())
area <- merge(area, district_stat, by='NOM')
area@data$density <- area@data$number/area@data$SUPERFICIE
#area@data %>%arrange(-density)

ncat <-  5
pal <- brewer.pal(ncat, "YlOrRd")
density <- area@data$density
class_density <- classIntervals(density,n=ncat, style="quantile")
col_density <- findColours(class_density, pal)

png(filename="C:/Users/Client/Desktop/density-area.png",
    type="cairo",
    units="in",
    width=5*2, 
    height=4*2, 
    pointsize=13,
    res=120)
par(bg = "grey90")
plot(area, col=col_density,border=rgb(0, 0, 0, 0.3))
title(main="Densité des logements à louer, Ville de Québec",sub="Source de données : kijiji.ca")
invisible(text(getSpPPolygonsLabptSlots(area), labels=as.character(area$NOM), cex=0.5))
dev.off()
#### Median price/ area ####
#area@data %>%arrange(-median_price)
price <- area@data$median_price
class <- classIntervals(price,n=ncat, style="equal",dataPrecision=0)
col_polygon <- findColours(class, pal)
legend_text <- str_replace(names(attr(col_polygon, "table")),",","$-")
legend_text <- str_replace(legend_text,"\\)","$")
legend_text <- str_replace(legend_text,"\\]","$")
legend_text <- str_replace(legend_text,"\\[","")

png(filename="C:/Users/Client/Desktop/price-area.png",
    type="cairo",
    units="in",
    width=5*2, 
    height=4*2, 
    pointsize=13,
    res=120)
par(bg = "grey90")
plot(area, col=col_polygon,border=rgb(0, 0, 0, 0.3))
title(main="Loyer médian, Ville de Québec",sub="Source de données : kijiji.ca")
legend("bottom",legend=legend_text, 
       fill=attr(col_polygon, "palette"), cex=0.6, bty="n",horiz=TRUE)
invisible(text(getSpPPolygonsLabptSlots(area), labels=as.character(area$NOM), cex=0.5))
dev.off()
#### Price standard deviation/ area ####
#area[area$number>=30,]@data %>%arrange(-sd_price)
sd_price<- area[area$number>=30,]@data$sd_price
class <- classIntervals(sd_price,n=ncat, style="equal",dataPrecision=0)
col_polygon <- findColours(class, pal)
legend_text <- str_replace(names(attr(col_polygon, "table")),",","$-")
legend_text <- str_replace(legend_text,"\\)","$")
legend_text <- str_replace(legend_text,"\\]","$")
legend_text <- str_replace(legend_text,"\\[","")

png(filename="C:/Users/Client/Desktop/sd-area.png",
    type="cairo",
    units="in",
    width=5*2, 
    height=4*2, 
    pointsize=12,
    res=120)
par(bg = "grey90")
plot(area[area$number>=30,], col=col_polygon,border=rgb(0, 0, 0, 0.3))
title(main="Écart type des loyers, Ville de Québec",sub="Source de données : kijiji.ca")
legend("bottom",legend=legend_text, 
       fill=attr(col_polygon, "palette"), cex=0.8, bty="n",horiz=TRUE)
invisible(text(getSpPPolygonsLabptSlots(area[area$number>=30,]), labels=as.character(area[area$number>=30,]$NOM), cex=0.8))
dev.off()