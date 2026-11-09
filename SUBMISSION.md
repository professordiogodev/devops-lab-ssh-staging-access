# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `ssh_config_snippet`: the `Host clippy-staging` block from your `~/.ssh/config`, committed (never commit private keys)
- [ ] `tunnel.txt`: the response you got from the private dashboard through your tunnel

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Your key was refused at first. Paste the line from the server log that explained why, and the command that fixed it. Which `ssh` flag showed you the client side of the story?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. What is the difference between your public key and your private key? Which file must never leave your machine, and what mode must it have?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. You disabled password login. In which order did you do the steps so you could not lock yourself out, and what would you have done if you had locked yourself out of a real server?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Explain what `ssh -L 8000:127.0.0.2:9000 clippy-staging` does, who connects to whom, and why a tunnel is better than opening port 9000 in the firewall.

**Your answer:**

<!-- replace this line with your answer -->

### Q5. How did you verify the transferred file was intact? Paste the checksums on both sides.

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `sudo ./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q7. **Tear down.** Paste the output of `sudo ./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
