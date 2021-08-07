write_r_script <- function(){

"
library(tidyverse)

ggplot(data = cars) +
  aes(x = dist) +
  aes(y = speed) +
  geom_point()


cars %>%
  count(speed) %>%
  arrange(-n)


df <- cars %>%
  mutate(id = 1:n())


"

}
