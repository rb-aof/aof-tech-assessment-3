# Submission notes

Submit this file in its own pull request (branch `submission-notes`) once you've opened your task PRs. The per-task details go in each PR's description; this file is the overall picture. Keep it short.

## Summary

| Task | Status (done / partial / not picked) | Pull request |
|---|---|---|
| 1. Bug fix | done | |
| 2. Moisture thresholds | done | |
| 3. Offline-first care log | not picked | |
| 4. Flutter: moisture thresholds | done | |

Roughly how long did you spend in total?
- 5 hours

## Prioritisation
- Which tasks did you pick for the 4 hours, and why? What did you skip or simplify?

I picked the bug task and the two simple feature tasks. I prefer finishing some small tasks in a limited time instead of choosing a big task but end up of unfinished. I think I finihshed most of the requirments in terms of the tasks I chose. I didn't write the unit test for the adding feature on flutter.

## Trade-offs and assumptions
- The tasks 3 is more complex regarding the scale. It has more states and interactive with backend and local storage. By carefully separate the big task into small taskes it can be done. Consideraing the time limitation, I picked the other three tasks in order to deliver a reliable and maintainable products.

## Things you noticed but didn't change
1. For the sensor detail page, maybe we can add a feature to automately refresh the page, so the new readings can be update in time.
2. The flutter project doesn't use a state management framework, the code might have different style from different developers, and a little bit difficult to read as well cause too much going on in the code. As the project is relatively small, it can be reasonable as well. If I have more time, I'll structure the project in more layer like networking, models, using BLoC or riverpod as the state managerment, etc.

## Use of AI tools (overall)

- If you used any: which ones, and how they fit into your workflow. Per-PR details go in the PR descriptions.

1. When I was reading the code, I asked AI to help me understand when there are some thing I don't understand immediately.
2. I am using copilot on both Xcode and VSCode, so it can help me generate code automately.



## Anything else we should know

- No
