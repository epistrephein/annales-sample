# Annales Sample

This repository contains the code to generate a sample of the Annales dataset,
which is a longitudinal bilingual corpus of news agency feeds, comprising
approximately 600,000 structured items harvested from ANSA and BBC News RSS
feeds from 2017 to the present day, and present it in a simple, single-page
website.

To generate the sample, the actual database of the Annales dataset is required,
which is not included in this repository.

## Usage

The scripts in this repository are both in Ruby and Python, so dependencies must
be installed for both:

```bash
bundle install
pip install -r requirements.txt
```

Copy the `.env-example` file to `.env` and fill in the actual Annales
`DATABASE_URL` environment variable:

```bash
cp -nv .env-example .env
```

Then run the default rake task to build all the components:

```bash
rake
```

The generated `index.html` file can be served as website.
