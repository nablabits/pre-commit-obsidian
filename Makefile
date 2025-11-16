test:
	bash ./sandbox/create-sandbox.sh && bash ./pre-commit-obsidian.sh --test

clean:
	bash ./sandbox/clean.sh