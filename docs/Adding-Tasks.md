---
layout: default
title: Adding Tasks
parent: User Guide
nav_order: 4
---

# Tasks

Every row within an outline can have a task associated with it, if desired.  To enable tasks to be assigned to rows, click on the Properties menubutton in the header bar and select the **Enable Tasks** feature.  By default, when this option is enabled, an unstarted task will be assigned to every row of the outline.  There are four task states that a row can be in:

1. No task assigned (no task checkbutton will be displayed for a row in this state)
2. Unstarted task (an empty checkbutton will be displayed)
3. In progress task (a checkbutton with a dash in it will be displayed)
4. Completed task (a checkbutton with a checkmark will be displayed)

Once a row has an unstarted task checkbutton assigned to it, it can be completed by clicking on the task checkbutton with the left mouse button.  To cycle a row's task state to other values, select the row to change by clicking on empty space to the left of the row text and use the lowercase T key to change the task state.  The state will change in the order above.  If a task is in the completed state, using the keyboard shortcut again will change the state to the "no task assigned" state.

If you change the task state of a row with a parent row, the parent row's task state will update accordingly.  The parent row state is set as follows:

- If all children have tasks in the "no task assigned" state, the parent row will also have a task state of "no task assigned".
- If all children have tasks in the "Unstarted" or "no task assigned" state, the parent row will also have a task state of "Unstarted".
- If all children have tasks in the "Completed" state, the parent row will also have a task state of "Completed".
- If the children have tasks in any other combination of states, the parent row will have a task state of "In progress".

Additionally, if the task state of a row is changed such that the row contains children rows, the children will assume the same state as the modified parent row.

To disable tasks for the entire outline, simply return to the Properties menubutton and deselect the **Enable Tasks** feature.
