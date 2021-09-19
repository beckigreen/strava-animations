##########################
####### Womens 100 #######
##########################

#### LIBRARIES ####
#Extracting and compiling Strava data
library(rStrava) 

#Tidying data
library(dplyr) 
library(tidyr)
library(purrr)

#Visualising data
library(ggplot2)
library(gganimate) 
library(ggmap)
library(ggimage)
library(ggtext)
library(magick) 

#### SET UP ####
#See Getting Started in README for further info

#Strava API - this needs to be filled in with your unique information
app_name <- 'xxxxx' 
app_client_id  <- 'xxxxx' 
app_secret <- 'xxxxxxxxxx' 
athlete_id <- 'xxxxx'

#Google API -  this needs to be filled in with your unique information
google_key <- 'xxxxxxxxxx' 

#Get strava token & retrieve athlete data
#this will open a tab where you can authorise access
stoken <- httr::config(token = strava_oauth(app_name, app_client_id, app_secret, app_scope="activity:read_all", cache=T))
myinfo <- get_athlete(stoken, athlete_id)

#Retrieve activity data
my_acts <- get_activity_list(stoken)
my_acts <- compile_activities(my_acts)
glimpse(my_acts)

#### PREPROCESS DATA ####
#Filtering for required data and converting variables into readable formats
my_acts_filt <- my_acts %>% 
  select(c('name', 'moving_time', 'distance', 'map.summary_polyline', 'start_date')) %>%
  arrange(start_date) %>%
  mutate(start_date = gsub("T.*$", '', start_date) %>%
           as.POSIXct(format = '%Y-%m-%d')) 

#Checking classes
sapply(my_acts_filt, class) 

#Selecting data of interest - Women's 100
my_acts_ride <- my_acts_filt %>% 
  filter(start_date == "2021-09-12")

#Using polyline data to get latitude and longitude, adding variable indicating the time sequence of data points
#Define function converting moving time into hours and minutes
hours_mins <- function(x){  
  time_hours <- x/3600
  hours <- floor(time_hours)  
  minutes <- signif((time_hours - hours)*60, 2)
  result <- paste(hours, "hours", minutes, "minutes")  
  return(result)  }

my_acts_ride <- my_acts_ride %>%
  group_by(name) %>%
  nest() %>%
  mutate(coords = map(data, function(x) get_latlon(x$map.summary_polyline, key=google_key)),) %>% #get latitude and longitude
  unnest(., c(data, coords)) %>%
  mutate(n = as.numeric(seq(1, n())), #time sequence
         moving_time = hours_mins(moving_time))

#Add bike icon for plotting - this icon link can be replaced with any image link you wish
image_link <- "https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/apple/271/bicycle_1f6b2.png"

image_link %>% 
  image_read() %>%
  image_transparent('white') %>% #remove background
  image_write(path = "bike_logo.png", format = "png") #write to image to read in

image_local <- "bike_logo.png"

my_acts_ride <- my_acts_ride %>% 
  mutate(image= image_local)

#### CREATE ANIMATION ####
#Get map background
bbox <- ggmap::make_bbox(lon, lat, data = my_acts_ride, f = 0.15)
map <- get_map(location = bbox, color = 'color', maptype = "terrain")

#Labels
plot_titles <- list(
  title = ("<strong>Women's 100k ride using <span style=\'color:#ffffff'\">Strava</span> data</strong>"),
  subtitle = ("<span style=\'color:#454545'\">**September 12th 2021** </span>"),
  caption = ("<span style=\'color:#454545'\">|| **Visualisation:** @becki_e_green</span>"))

#Plot
p = ggmap(map) +
  geom_path(data = my_acts_ride, aes(x = lon, y = lat), col="#ff7f00", size=0.7) +
  geom_image(data = my_acts_ride, aes(image = image), size = 0.06) + 
  transition_reveal(n) +   
  labs(title = plot_titles$title, subtitle =  plot_titles$subtitle, caption = plot_titles$caption) +
  theme(plot.title = element_markdown(size=15), plot.subtitle = element_markdown(size=12), plot.caption = element_markdown(size=10),
        legend.position="none", axis.text=element_blank(), axis.ticks = element_blank(), 
        axis.title = element_blank(), plot.background = element_rect(fill = "darkorange1"))

gganimate::animate(p, res=100, fps=15, h=500, w=500, bg = 'transparent')
anim_save("animations/womens100_anim.gif")

########END########