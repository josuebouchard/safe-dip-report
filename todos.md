# Report to-do list

Everything that is still open in the report, collected here so that the PDF has no
to-do boxes. Section numbers are those of the Nov 13 draft. Items marked **(you)** need
information or a photo only the team has.

## Missing links, videos and pictures

- [ ] **Gantry video.** Upload it to the website and add a numbered video entry in
      Section 3.6, Final Design. Cite it as evidence in the requirement tests it shows,
      for example R-06, with a caption that says what it shows and at what time.
- [ ] **Dashboard screen recording.** Upload it, add a video entry in Section 3.2.9
      (Communications and Monitoring), and cite it as evidence for R-09 and for the
      emergency-stop fault (Fig. 3.15).
- [ ] **Final photos of the finished product** for Section 3.6 (due in the final report,
      Nov 20): clear, labeled, and sharper than the video frame used now (Fig. 3.22).
- [ ] **Close photo of the mounted limit switches** (optional). Figure 3.12 is a crop of a
      low-resolution video frame.

## Pictures and captions to review

- [ ] **(you)** Fig. 3.12: check that the X and Y rings are on the right parts (X at the end
      of the upper rail, Y on the carriage plate).
- [ ] **(you)** The two photos from the roadblocks PDF: the holder repair with L-brackets
      (Section 3.3, Damaged Leadscrew Holder) and the frame L-support (Frame Wobble).
      The captions assume that is what they show.
- [ ] Figures 3.14 and 3.15 (the dashboard): confirm they show what the captions say.
- [ ] Chapter 2 CAD pictures still show the proposal design with two conveyors, and have no
      dimension lines. **Needed for the final report (Nov 20):** a dimensioned drawing of
      the as-built assembly, from Adriano. The Week 5 plate drawings on the website have
      dimensions and could be a stopgap.

## Text still to write

- [ ] **Part-ready trigger** (Section 3.1.1 describes the design, which is not in the
      firmware yet). After implementing it, test R-01 and R-06, rewrite that part in past
      tense, and update the cycle diagram, the table of operations, the Modbus map, the
      monitor's stage list, and the verification table.
- [ ] **First homing test of both axes** (Section 3.2.6, Sensing).
- [ ] **(you)** Section 3.2.6 says a printed holder was made for the switches, but the
      switches are glued in place. Check that the two statements agree.

## Test results to fill in (Section 3.4)

Only measured values go in. Anything not measured stays "Not yet tested".

- [ ] Trial counts and formal measurements for every requirement.
- [ ] R-01 (trigger), R-04 (immersion depth) and R-10 (ten cycles): not yet run.
- [ ] R-05 (dwell time): results say "Not yet documented".
- [ ] R-07 and R-08: wait for the replacement of the failed motor-supply relay, then test
      and document them.
- [ ] R-09: check the recording shows each stage in order and a fault appearing while the
      machine runs. If it does, the requirement can be marked as met, then update the
      verification table.
- [ ] R-11: the evidence is the informal test on the website. Record the exact weight, the
      trials, and a video.
- [ ] R-02: the Y error was only estimated. Repeat it with a measurement.

## Must match the website

The report now uses the website's status words, so the statuses agree. The list of what
to change on the website is in [website-updates.md](website-updates.md).

- [ ] Apply the changes in `website-updates.md`.
- [ ] Modbus monitor (firmware repository, not the website): the parameter table still
      shows X positions with a range of "0–400 mm", but the firmware allows 0 to 550.
      Check also that it uses 800 steps/mm for Y.

## Before the final report (Nov 20)

- [ ] Rerun the firmware-size chart
      (`images/chapter-3/implementation/firmware-size-over-time/loc_history.py`).
- [ ] Check the code listings in Appendix A and the monitor listings (A.9 to A.11) against
      the final firmware.
- [ ] The chapter describes the firmware on `fix/review-findings`, which is not merged into
      `main`. Merge it, or update the chapter if it changes.
- [ ] Appendix C is a list of datasheets, not the pages used. The writing guide asks for the
      pages. Left as is for now.
- [ ] Confirm the final 12 V adapter (the one used for the first tests was not the final
      one).
- [ ] Rewrite the abstract and conclusion with the final results.

## Submitting

- [ ] Commit the report changes. Nothing has been committed since the Mermaid commit.
- [ ] Push the branch. The push over SSH fails from this machine ("Permission denied
      (publickey)"), so fix the key or push another way.
- [ ] Build the PDF, upload it to Canvas, and post the same PDF on the website's Project
      Documents page.
