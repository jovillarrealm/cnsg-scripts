library(tidyverse)

# Load the data
recs <- read.csv(
  file = "/home/portatilcnsg/Desktop/JoRepos/csng-scripts/recs.csv",
  header = TRUE,
  sep = ";"
)

# Group, summarize, and sort the data for avg_user_time
recs_sorted_grouped <- recs %>%
  group_by(comparisons) %>%
  summarize(
    avg_user_time = mean(user_time, na.rm = TRUE),
    total_comparisons_number = sum(comparisons_number, na.rm = TRUE)
  ) %>%
  arrange(total_comparisons_number) %>%
  mutate(comparisons = factor(comparisons, levels = comparisons))

# Group, summarize, and sort the data for mrss
recs_sorted_grouped_mrss <- recs %>%
  group_by(comparisons) %>%
  summarize(
    mrss = mean(mrss, na.rm = TRUE),
    total_comparisons_number = sum(comparisons_number, na.rm = TRUE)
  ) %>%
  arrange(total_comparisons_number) %>%
  mutate(comparisons = factor(comparisons, levels = comparisons))

# Plot for avg_user_time
plot_user_time <- ggplot(recs_sorted_grouped, aes(x = comparisons, y = avg_user_time)) +
  geom_bar(stat = "identity") +
  scale_y_log10() +
  labs(
    title = "FastANI's plot of log(User Time (s)) by Comparisons",
    x = "Comparisons (QxR)",
    y = "log(Average User Time) (s)"
  ) +
  geom_text(aes(label = paste(round(avg_user_time / 3600, 3), "h"), vjust = -0.5)) +
  theme_classic()

png()

# Plot for mrss
plot_mrss <- ggplot(recs_sorted_grouped_mrss, aes(x = comparisons, y = mrss)) +
  geom_bar(stat = "identity") +
  scale_y_log10() +
  labs(
    title = "FasANI's Plot of log(MRSS (KB)) by Comparisons",
    x = "Comparisons (QxR)",
    y = "log(Maximum Resident Set Size) (KB)"
  ) +
  geom_text(aes(label = paste(round(mrss / (1024 * 1024), 0), "GB"), vjust = -0.5)) +
  theme_classic()

# Print both plots explicitly
print(plot_user_time)
print(plot_mrss)
