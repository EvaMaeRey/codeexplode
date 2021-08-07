library(tidyverse)


ggplot(data = cars) +
  aes(x = dist) +
  aes(y = speed) +
  geom_point()


cars %>%
  count(speed) %>%
  arrange(-n)


# hola po
df <- cars %>%
  mutate(id = 1:n())
