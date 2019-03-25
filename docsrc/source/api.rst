.. _API:

API — The MG-RAST Application Programming Interface
===================================================

URLs
----

::

   https://api.mg-rast.org/

Further documentation, with a complete parameter listing for all
resources available is at:

::

   https://api,mg-rast.org/api.html

Github repository of script tools, examples, and contributed code for
using the MG-RAST API:

::

   https://github.com/MG-RAST/MG-RAST-Tools

.. _introduction-1:

Introduction
------------

Over 110,000 metagenomic data sets have been uploaded and analyzed in
MG-RAST since 2007, totaling over 43 terabases (TBp). Data uploaded
falls in three classes: shotgun metagenomic data, amplicon data, and,
more recently, metatranscriptomic data. The MG-RAST pipeline normalizes
all samples by applying a uniform pipeline with the appropriate quality
control mechanisms for the various data sources. Uniform processing and
robust sequence quality control enable comparison across experimental
systems and, to some extent, across sequencing platforms. With the
inclusion of standardized metadata MG-RAST has enabled meta-analysis
available through its web-based user interface. This provides an
easy-to-use way to upload and download data, perform analyses, and
create and share projects.

As with most GUIs, however, there are limitations to what can be done,
for example, regarding the number of samples processed in a single
analysis, access to complete metadata, and easy access to raw data and
quality metrics for each sample. As part of the DOE Systems Biology
knowledgebase project (KBase) we have implemented a web services
application programmers interface (API) that exposes all data to
(authenticated) programmers, enabling access to available data and
functionality through software applications. This makes user access to
MG-RAST’s internal data structures possible.

The MG-RAST API enables programmatic access to data and analyses in
MG-RAST without requiring local installations. Using the API, users can
authenticate against the service, submit their data, download results,
and perform extensive comparisons of data sets. The API uses the
Representational State Transfer (REST) [3] architecture which allows
download of data in ASCII format, allowing users to query the system via
URLs and returning MG-RAST data objects in their native format (e.g.
similarity tables or sequence files). For structured data (e.g. metadata
or project information) the MG-RAST API uses JSON (Javascript Object
Notation, a widely used standard) as its data format.

This allows users to use simple tools to download data files or view the
JSON in their web browsers using one of the many available JSON viewers.
In addition many programming languages have libraries for convenient
HTTP interaction and JSON conversions. The API has a minimal number of
prerequisites; and any language with HTTP and JSON support or command
line utilities such as “curl" can easily integrate with the design.

If you are not a programmer or you are not willing to spend the time
learning the API, the Example scripts (see chapter
`7 <#API-Examples>`__.)

Design and Implementation
-------------------------

The MG-RAST API enables programmatic access to data and analyses in
MG-RAST without requiring local installations. Users can authenticate
against the service, submit their data, download results, and perform
extensive comparisons of data sets. We chose to use the Representational
State Transfer (REST) [3] architecture. The REST approach allows
download of data in ASCII format, allowing users to query the system via
URLs and returning MG-RAST data objects in their native format (e.g.
similarity tables or sequence files). For structured data (e.g. metadata
or project information) the MG-RAST API uses JSON (Javascript Object
Notation, a widely used standard) as its data format.

Using this approach users can use simple tools to download data files to
their machines or view the JSON in their web browsers using one of the
many available JSON viewers. In addition many programming languages have
libraries for convenient HTTP interaction and JSON conversions.

Most of the API calls are simply URLs which can be entered in the
address bar of a web browser to perform the download through the
browser. These URLs can also be used with a command line tool like curl,
in programing-language-specific libraries, or in command line scripts.
The examples in the Results section illustrate the use of each of these
methods. The example scripts are available on in the supplementary
materials and on github (https://github.com/MG-RAST/MG-RAST-Tools) along
with other useful illustrative scripts.

The MG-RAST API covers most of the functionality available through the
MG-RAST website, with access to annotations, analyses, metadata and
access to the MG-RAST user inbox to view contents as well as upload
files. All sequence data and data products from intermediate stages in
the analysis pipeline are available for download. Other resources
provide services not available through the website, e.g. the m5nr
resource lets you query the m5nr database.

Each query to the API is represented as a URI beginning with

::

   https://api.mg-rast.org/

and has a defined structure to pass the requests and parameters to the
API server. These URI queries can be used from the command line, e.g.
using curl, in a browser, or incorporated in a shell script or program.

Each URI has the form:

::

   https://api.mg-rast.org/{version}/{resourcepath}?{querystring}

where

::

   {version}

explicitly directs the request to a specific version of the API. If it
is omitted the latest API version will be used. The current version
number is ‘1’.

::

   {resourcepath}

is constructed from the path parameters listed below to define a
specific resource.

::

   {querystring}

is used to filter the results obtained for the resource, this is
optional.

For example, in:

::

   https://api.mg-rast.org/1/annotation/sequence/mgm4447943.3?evalue=10&type=organism&source=SwissProt

the resource path

::

   annotation/sequence/mgm4447943.3

defines a request for the annotated sequences for the MG-RAST job with
ID 4447943.3. The optional query string

::

   evalue=10&type=organism&source=SwissProt

modifies the results by setting an evalue cutoff, annotation type and
database source.

The API provides an authentication mechanism for access to private
MG-RAST jobs and users’ inbox. The ’auth_key’ (or ’webkey’) is a 25
character long string, e.g.

::

   j6FNL61ekNarTgqupMma6eMx5

which is used by the API to identify an MG-RAST user account and
determine access rights to metagenomes. Note that the auth_key is valid
for a limited time after which queries using the key will be rejected.
You can create a new auth_key or view the expiration date and time of an
existing auth_key on the MG-RAST website. An account can have only one
valid auth_key and creating a new key will invalidate an existing key.

All public data in MG-RAST is available without an auth_key. All API
queries for private data which either do not have an auth_key or use an
invalid or expired auth_key will get a "insufficient permissions to view
this data" response.

The auth_key can be included in the query string like:

::

   https://api.mg-rast.org/1/annotation/sequence/mgm4447943.3?evalue=10&type=organism&source=SwissProt&auth_key=j6FNL61ekNarTgqupMma6eMx5

or in a request using curl like:

::

   curl -X GET -H "auth: j6FNL61ekNarTgqupMma6eMx5" "https://api.mg-rast.org/1/annotation/sequence/mgm4447943.3?evalue=10&type=organism&source=SwissProt"

Note that for the curl command the quotes are necessary for the query to
be passed to the API correctly.

If an optional parameter passed through the query string has a list of
values only the first will be used. When multiple values are required,
e.g. for multiple md5 checksum values, they can be passed to the API
like:

::

   curl -X POST -d '{"data":["000821a2e2f63df1a3873e4b280002a8","15bf1950bd9867099e72ea6516e3d602"]}' "https://api.mg-rast.org//m5nr/md5"

In some cases, the data requested is in the form of a list with a large
number of entries. In these cases the ‘limit’ and ‘offset’ parameters
can be used to step through the list, e.g.

::

   https://api.mg-rast.org/1/project?order=name&limit=20&offset=100

will limit the number of entries returned to 20 with an offset of 100.
If these parameters are not provided default values of ``limit=10`` and
``offset=0`` are used. The returned JSON structure will contain the
‘next’ and ‘prev’ (previous) URIs to simplify stepping through the list.

The data returned may be plain text, compressed gzipped files or a JSON
structure.

Most API queries are ‘synchronous’ and results are returned immediately.
Some queries may require a substantial time to compute results, in these
cases you can select the asynchronous option by adding
``‘&asynchronous=1’`` to the end of the query string. This query will
then return a URL which will return the query results when they are
ready.

Most of the API calls are simply URLs which can be entered in the
address bar of a web browser to perform the download through the
browser. These URLs can also be used with a command line tool like curl,
in programing-language-specific libraries, or in command line scripts.
The examples below illustrate the use of each of these methods. The
example scripts are available on the github site along with other useful
illustrative scripts.

.. table:: Top-level resources available through the MG-RAST-API

   =================== ======================================================================================================
   **Resource/Object** **Description**
   =================== ======================================================================================================
   **annotation**      taxonomic and functional annotations made by comparison with the M5nr database
   **compute**         resource to compute PCoA , heatmap, and normalization for a set of input metagenomes
   **download**        download results of the MG-RAST pipeline
   **inbox**           upload and listing of data in the staging area prior to execution of the MG-RAST pipeline
   **library**         library information for uploaded metagenome provided by the user
   **matrix**          abundance profiles in BIOM (5) format for a list of metagenomes
   **M5nr**            access M5 nonredundant protein database used for annotation of metagenomic sequences
   **metadata**        creation, export, and validation of metadata templates and spreadsheets
   **metagenome**      container for sample, library, project, and precomputed data for an uploaded metagenomic sequence file
   **profile**         returns a single data object in BIOM format
   **project**         project summary for metagenome provided by user
   **sample**          sample information provided by user
   **search**          search MG-RAST by MG-ID, metadata, function, or taxonomy; or implement a more complex search.
   **validation**      validates templates for correct structure and data
   =================== ======================================================================================================

[table:upload_speeds]

Examples
--------

The API provides index-driven access to data subsets using the following
data types as indices into the data: functions, functional hierarchy
data, and taxonomic data. Whenever possible we have employed standards
to expose data and metadata, such as the BIOM standard for encoding
abundance profiles. The examples below are intended to illustrate usage
for the various resources available, they do not cover the entire
functionality of the API, see the documentation at the API website for
the comprehensive listing.

-  **annotation**

   ::

      https://api.mg-rast.org/1/annotation/sequence/mgm4440036.3?type=function&filter=protease&source=Subsystems

   Retrieve the reads from a metagenome with ID mgm4440036.3 which were
   annotated as protease in SEED Subsystems.

-  **download**

   ::

      https://api.mg-rast.org/1/download/mgm4447943.3

   Retrieve information formatted as a JSON object about all the files
   available for download for metagenome mgm4447943.3 with information
   about the files and sequence statistics where applicable. Each file
   listed has a URL included which can be used to download the file,
   e.g.

   ::

      https://api.mg-rast.org/1/download/mgm4447943.3?file=650.1

   will download the protein.sims file containing the BLAT similarities.

-  **inbox**

   ::

      curl -X POST -H "auth: auth_key" -F "upload=@sequences.fastq" "https://api.mg-rast.org/1/inbox"

   Upload the file ’sequences.fastq’ to your inbox. This API call
   requires user authentication using the auth_key described above. It
   can not be used in a browser, but needs to be run from the command
   line or from a script.

-  **matrix**

   ::

      https://api.mg-rast.org/matrix/organism?group_level=family&source=SEED&evalue=5&id=mgm4440442.5&id=mgm4440026.3

   Retrieve the taxonomic abundance profile on family level for 2
   metagenomes based on SEED assignments with an evalue cutoff of 1e-5.

-  **metagenome**

   ::

      https://api.mg-rast.org/1/metagenome/mgm4440026.3

   List analysis submission parameters and other details for a
   metagenome. The metagenome resource can also be used to search
   metadata, function and taxonomy.

   ::

      https://api.mg-rast.org/metagenome?function=dnaA&organism=coli&biome=marine&match=all&order=created

   This call will find all marine metagenomes with reads annotated as
   dnaA and have taxonomic assignment containing the text ‘coli’, the
   results will be ordered based on creation date for the metagenome.

-  **project**

   ::

      https://api.mg-rast.org/project/mgp31?verbosity=full

   Retrieve available information about the project with ID mgp31.

-  **sample**

   ::

      https://api.mg-rast.org/1/sample/mgs12326?verbosity=full

   Retrieve available information about individual samples, including
   IDs and metadata.

-  **metadata**

   ::

      https://api.mg-rast.org//metadata/template

   Retrieve the static template for metadata object relationships and
   types used by MG-RAST.

   ::

      https://api.mg-rast.org//metadata/export/mgp128

   Retrieve all metadata for project mgp128.

   ::

      https://api.mg-rast.org/metadata/cv

   Retrieve a set of lists of all our controlled metadata terms,
   including the ontologies.

   ::

      https://api.mg-rast.org/metadata/ontology?name=biome&version=2013-04-27

   Retrieve a more detailed list (with relationships) for a specific
   version of the ontology.

-  **m5nr**

   ::

      https://api.mg-rast.org/1/m5nr/md5/ffc62262a18b38671c3e337150ef535f?source=SwissProt

   Retrieve the UniProt ID for a given sequence identifier.

.. _API-Examples:

Example scripts using the MG-RAST REST API
==========================================

.

.. _introduction-2:

Introduction
------------

As part of the RESTful API (see chapter `6 <#API>`__), we are providing
a collection of example scripts.

Each script has comments in the source code as well as a help function.
This document provides a brief overview of the available scripts and
their intended purpose. Please see the help associated with all of the
individual files for a complete list of options and more details.

We believe these scripts to be the best starting point for many users,
he we attempt to provide a listing of the most important tools.

.. _urls-1:

URLs
~~~~

The Examples are located on github at:

::

   https://github.com/MG-RAST/MG-RAST-Tools

This is the base directory for the rest of this chapter, go here to find
the tools and examples described below:

::

   https://github.com/MG-RAST/MG-RAST-Tools/tree/master/tools/bin

Each script has a verbose help option (–help) to list all options and
explain their usage.

Download DNA sequence for a function – mg-get-sequences-for-function.py
-----------------------------------------------------------------------

This script will retrieve sequences and annotation for a given function
or functional class.

The output is a tab-delimited list of: m5nr id, dna sequence, semicolon
seperated list of annotations, sequence id.

**Example:**

::


       mg-get-sequences-for-function.py --id "mgm4441680.3" --name "Central carbohydrate metabolism" --level level2 --source Subsystems --evalue 10

Download DNA sequences for a taxon or taxonomic group– mg-get-sequences-for-taxon.py
------------------------------------------------------------------------------------

This script will retrieve sequences and annotation for a given taxon or
taxonomic group.

The output is a tab-delimited list of: m5nr id, dna sequence, semicolon
seperated list of annotations, sequence id

**Example:**

::

       mg-get-sequences-for-taxon.py --id "mgm4441680.3" --name Lachnospiraceae --level family --source RefSeq --evalue 8

Download sequences annotated with function and taxonomy – mg-get-annotation-set.py
----------------------------------------------------------------------------------

Retrieve functional annotations for given metagenome and organism.

The output is a tab-delimited list of annotations: feature list,
function, abundance for function, avg evalue for function, organism.

**Example:**

::

       mg-get-annotation-set.py --id "mgm4441680.3" --top 5 --level genus --source SEED

Download the n most abundant functions for a metagenome – mg-abundant-functions.py
----------------------------------------------------------------------------------

Retrieve the top n abundant functions for metagenome.

The output is a tab-delimited list of function and abundance sorted by
abundance (largest first). ’top’ option controls number of rows
returned.

**Example:**

::

       mg-abundant-functions.py --id "mgm4441680.3" --level level3 --source Subsystems --top 20 --evalue 8

Download and translate similarities into different namespaces e.g. SEED or GenBank – m5nr-tools.pl
--------------------------------------------------------------------------------------------------

MG-RAST computes similarities against a non-redundant database (Wilke et
al. 2012) and later translates them into any of the supported
namespaces. As a result you can view your annotations (or indeed the
similarity results) in each of these namespaces. Sometimes this can lead
to new features and or differences becoming visible that would otherwise
be obscured.

m5nr-tools can translate accession ids, md5 checksums, or protein
sequence into annotations. One option for output is a blast m8 formatted
file.

**Example:**

::

   m5nr-tools.pl --api "https://api.mg-rast.org/1" --option annotation --source RefSeq --md5 0b95101ffea9396db4126e4656460ce5,068792e95e38032059ba7d9c26c1be78,0b96c92ce600d8b2427eedbc221642f1

Download multiple abundance profiles for comparison – mg-compare-functions
--------------------------------------------------------------------------

Retrieve matrix of functional abundance profiles for multiple
metagenomes. The output is either tab-delimited table of functional
abundance profiles, metagenomes in columns and functions in rows or BIOM
format of functional abundance profiles.

**Example:**

::

       mg-compare-functions.py --ids "mgm4441679.3,mgm4441680.3,mgm4441681.3,mgm4441682.3" --level level2 --source KO --format text --evalue 8

Standard operating procedures SOPs for MG-RAST
==============================================

SOP - Metagenome submission, publication and submission to INSDC via MG-RAST
-----------------------------------------------------------------------------

MG-RAST can be used to host data for public access. There are three
interfaces for uploading and publishing data, the Web interface,
intended for most users, command line scripts, intended for programmers,
and the native RESTful API, recommended for experienced programmers.

When data is published in MG-RAST, it can also be released to the INSDC
databases. This tutorial covers both use cases.

We note that MG-RAST provides temporary IDs and permanent public
identifiers. The permanent identifiers are assigned at the time data is
made public. Permanent MG-RAST identifiers begin with “mgm” (e.g.
“mgm4449249.3”) for data sets and mgp (e.g.”mgp128”) for
projects/studies.

The following data types are supported:

-  Shotgun metagenomes (“raw” and assembled)

-  Metatranscriptome data (“raw” and assembled)

-  Ribosomal amplicon data (16s, 18s, ITS amplicons)

-  Metabarcoding data (e.g. cytochrome C amplicons; basically all non
   ribosomal amplicons)

PLEASE NOTE: We strongly prefer raw data over assembled data, if you
submit assembled data, please submit the raw reads in parallel. If you
perform local optimization e.g. adapter removal or quality clipping,
please submit the raw data as well.

Audience:
^^^^^^^^^

This document is intended for experienced to very experienced users and
programmers. We recommend that most users not use the RESTful API. There
is also a document describing data publication and INSDC submission via
the web UI.

Requirements:
^^^^^^^^^^^^^

An access token for the MG-RAST API, this can be obtained from the
MG-RAST web page (http://mg-rast.org) in the user section.

You will need a working python interpreter and the command line scripts
and example data can be found in
https://github.com/MG-RAST/MG-RAST-Tools:

Scripts: MG-RAST-Tools/tools/bin Data: MG-RAST-Tools/examples/sop/data

Change into MG-RAST-Tools/examples/sop/data and call:

::

   sh get_test_data.sh

to add additional example data.

Either download the repository as a zipped archive from
https://github.com/MG-RAST/MG-RAST-Tools/archive/master.zip or use the
git command line tool:

::

   git clone http://github.com/MG-RAST/MG-RAST-Tools.git

We tested up to the following parameters:

-  max. size per file: 10GB

-  max. project size: 200 metagenomes

While there is no reason to assume the software will not work with
larger numbers of files or larger files, we did not test for that.

SOP:
~~~~

Upload and submit sequence data and metadata to MG-RAST using the
command mg-submit.py Note: This is an asynchronous process that may take
some time depending on the size and number of datasets. (Note: We
recommend that novice users try the web frontend; the cmd-line is
primarily intended for programmers) The metadata in this example is in
Microsoft Excel format, there is also an option of using JSON formatted
data. Please note: We have observed multiple problems with spreadsheets
that were converted from older version of Excel or “compatible” tools
e.g. OpenOffice.

Example:

::

   mg-submit.py submit simple  ....  --metadata

Verify the results and obtain a temporary identifier E.g. by using the
WebUI at http://mg-rast.org – you can also use that to publish the data
and trigger submission to INSDC.

Publish your project in MG-RAST and obtain a stable and public MG-RAST
project identifier

Note: once the data is made public the data is read only, but metadata
can be improved

Example:

::

   mg-project make-public $temporary_ID

Trigger release to INSDC/ submit to EBI

Note: Metadata updates are automatically synced with INSDC databases
within 48 hours.

Example:

::

   mg-project submit-ebi $PROJECT_ID

Check status of release to INSDC/ submission to EBI

Note: This is an asynchronous process that may take some time depending
on the size and number of datasets.

Example:

::

   mg-project status-ebi $PROJECT_ID

We include a sample submission below:

::

   From within the MG-RAST-Tool repository directory

   # Retrieve repository and setup environment
   git clone http://github.com/MG-RAST/MG-RAST-Tools.git
   cd MG-RAST-Tools

   # Path to scripts for this example
   PATH=$PATH:`pwd`/tools/bin

   # set environment variables
   source set_env.sh

   # Set credentials, obtain token from your user preferences in the UI
   mg-submit.py login --token

   # Create metadata spreadsheet. Make sure you map your samples to your
   # sequence files
   # Upload metagenomes and metadata to MG-RAST

   mg-submit.py submit simple \
              examples/sop/data/sample_1.fasta.gz \
              examples/sop/data/sample_2.fasta.gz \
              --metadata examples/sop/data/metadata.xlsx

   # Output
   > Temp Project ID: ed2102aa666d676d343735323836382e33
   > Submission ID: 77a1a1a5-4cbd-4673-86bf-f87c9096c3e1

   # Remember IDs for later use
   SUBMISSION_ID=77a1a1a5-4cbd-4673-86bf-f87c9096c3e1
   TEMP_ID=mgp128

   # Check if project is finished
   mg-submit.py status $SUBMISSION_ID

   # Output
   > Submission: 77a1a1a5-4cbd-4673-86bf-f87c9096c3e1 Status: in-progress


   # Make project public in MG-RAST
   mg-project.py make-public $TEMP_ID

   # Output
   > # Your project is public.
   > Project ID: mgp128
   > URL: https://mg-rast.org/linkin.cgi?project=mgp128
   PROJECT_ID=mgp128

   # Release project to INSDC archives
   mg-project.py submit-ebi $PROJECT_ID

   # Output
   > # Your Project mgp128 has been submitted
   > Submission ID: 0cf7d811-1d43-4554-ab97-3cb1f5ceb6aa

   # Check if project is finished
   mg-project.py status-ebi $PROJECT_ID

   # Output
   > Completed
   > ENA Study Accession: ERP104408


Acknowledgments
---------------

This project is funded by the NIH grant R01AI123037 and by NSF grant
1645609

This work used the Magellan machine (U.S.Department of Energy, Office of
Science, Advanced Scientific Computing Research, under contract
DE-AC02-06CH11357) at Argonne National Laboratory, and the PADS resource
(National Science Foundation grant OCI-0821678) at the Argonne National
Laboratory/University of Chicago Computation Institute.

In the past the following sources contributed to MG-RAST development:

-  U.S. Dept. of Energy under Contract DE-AC02-06CH11357

-  Sloan Foundation (SLOAN #2010-12),

-  NIH NIAID (HHSN272200900040C),

-  NIH Roadmap HMP program (1UH2DK083993-01).



.. container:: references
   :name: refs

   .. container::
      :name: ref-CLOVR

      Angiuoli, S. V., M. Matalka, A. Gussman, K. Galens, M. Vangala, D.
      R. Riley, C. Arze, J. R. White, O. White, and W. F. Fricke. 2011.
      “CloVR: A Virtual Machine for Automated and Portable Sequence
      Analysis from the Desktop Using Cloud Computing.” *BMC
      Bioinformatics* 12: 356.

   .. container::
      :name: ref-RAST

      Aziz, Ramy, Daniela Bartels, Aaron Best, Matthew DeJongh, Terrence
      Disz, Robert Edwards, Kevin Formsma, et al. 2008. “The RAST
      Server: Rapid Annotations Using Subsystems Technology.” *BMC
      Genomics* 9 (1): 75. https://doi.org/10.1186/1471-2164-9-75.

   .. container::
      :name: ref-GENBANK

      Benson, D. A., M. Cavanaugh, K. Clark, I. Karsch-Mizrachi, D. J.
      Lipman, J. Ostell, and E. W. Sayers. 2013. “GenBank.” *Nucleic
      Acids Res* 41 (Database issue): D36–42.

   .. container::
      :name: ref-OPENMP

      Board, OpenMP Architecture Review. 2011. “OpenMP Application
      Program Interface Version 3.1.”

   .. container::
      :name: ref-CRISPRS

      Bolotin, A., B. Quinquis, A. Sorokin, and S. D. Ehrlich. 2005.
      “Clustered Regularly Interspaced Short Palindrome Repeats
      (CRISPRs) Have Spacers of Extrachromosomal Origin.” *Microbiology*
      151 (Pt 8): 2551–61.

   .. container::
      :name: ref-DIAMOND

      Buchfink, Benjamin, Chao Xie, and Daniel H Huson. 2015. “Fast and
      Sensitive Protein Alignment Using Diamond.” *Nature Methods* 12
      (1): 59–60.

   .. container::
      :name: ref-QIIME

      Caporaso, J. G., J. Kuczynski, J. Stombaugh, K. Bittinger, F. D.
      Bushman, E. K. Costello, N. Fierer, et al. 2010. “QIIME Allows
      Analysis of High-Throughput Community Sequencing Data.” *Nat
      Methods* 7 (5): 335–6.

   .. container::
      :name: ref-RDP

      Cole, J. R., B. Chai, T. L. Marsh, R. J. Farris, Q. Wang, S. A.
      Kulam, S. Chandra, et al. 2003. “The Ribosomal Database Project
      (RDP-II): Previewing a New Autoaligner That Allows Regular Updates
      and the New Prokaryotic Taxonomy.” *Nucleic Acids Research* 31
      (1): 442–43. http://www.ncbi.nlm.nih.gov/pmc/articles/PMC165486/.

   .. container::
      :name: ref-SOLEXAQA

      Cox, M. P., D. A. Peterson, and P. J. Biggs. 2010. “SolexaQA:
      At-a-Glance Quality Assessment of Illumina Second-Generation
      Sequencing Data.” *BMC Bioinformatics* 11: 485.

   .. container::
      :name: ref-GREENGENES

      DeSantis, T. Z., P. Hugenholtz, N. Larsen, M. Rojas, E. L. Brodie,
      K. Keller, T. Huber, D. Dalevi, P. Hu, and G. L. Andersen. 2006.
      “Greengenes, a Chimera-Checked16S rRNA Gene Database and Workbench
      Compatible with ARB.” *Appl. Environ. Microbiol.* 72 (7): 5069–72.
      https://doi.org/10.1128/aem.03006-05.

   .. container::
      :name: ref-UCLUST

      Edgar, R. C. 2010. “Search and Clustering Orders of Magnitude
      Faster Than BLAST.” *Bioinformatics* 26 (19): 2460–1.

   .. container::
      :name: ref-GSC

      Field, D., L. Amaral-Zettler, G. Cochrane, J. R. Cole, P. Dawyndt,
      G. M. Garrity, J. Gilbert, F. O. Glöckner, L. Hirschman, and I.
      Karsch-Mizrachi. 2011. “The Genomic Standards Consortium.” *PLOS
      Biology* 9 (6): e1001088.

   .. container::
      :name: ref-SKYPORT

      Gerlach, Wolfgang, Wei Tang, Kevin Keegan, Travis Harrison,
      Andreas Wilke, Jared Bischof, Mark D’Souza, et al. 2014. “Skyport:
      Container-Based Execution Environment Management for Multi-Cloud
      Scientific Workflows.” In *Proceedings of the 5th International
      Workshop on Data-Intensive Computing in the Clouds*, 25–32.
      DataCloud ’14. Piscataway, NJ, USA: IEEE Press.
      https://doi.org/10.1109/DataCloud.2014.6.

   .. container::
      :name: ref-ADRS

      Gomez-Alvarez, V., T. K. Teal, and T. M. Schmidt. 2009.
      “Systematic Artifacts in Metagenomes from Complex Microbial
      Communities.” *ISME J* 3 (11): 1314–7.

   .. container::
      :name: ref-HUSEPYRO

      Huse, S. M., J. A. Huber, H. G. Morrison, M. L. Sogin, and D. M.
      Welch. 2007. “Accuracy and Quality of Massively Parallel DNA
      Pyrosequencing.” *Genome Biol* 8 (7): R143.

   .. container::
      :name: ref-MEGAN

      Huson, D. H., A. F. Auch, J. Qi, and S. C. Schuster. 2007. “MEGAN
      Analysis of Metagenomic Data.” *Genome Res* 17 (3): 377–86.

   .. container::
      :name: ref-NHGRI_COST

      Institute, National Human Genome Research. 2012. “Cost Per Raw
      Megabase of Dna Sequence.”
      `http://www.genome.gov/images/content/cost\_per\_megabase.jpg <http://www.genome.gov/images/content/cost\_per\_megabase.jpg>`__.

   .. container::
      :name: ref-EGGNOG

      Jensen, L. J., P. Julien, M. Kuhn, C. von Mering, J. Muller, T.
      Doerks, and P. Bork. 2008. “EggNOG: Automated Construction and
      Annotation of Orthologous Groups of Genes.” *Nucleic Acids Res* 36
      (Database issue): D250–4.

   .. container::
      :name: ref-KEGG

      Kanehisa, M. 2002. “The KEGG Database.” *Novartis Found Symp* 247:
      91–101; discussion 101–3, 119–28, 244–52.

   .. container::
      :name: ref-DRISEE

      Keegan, K. P., W. L. Trimble, J. Wilkening, A. Wilke, T. Harrison,
      M. D’Souza, and F. Meyer. 2012. “A Platform-Independent Method for
      Detecting Errors in Metagenomic Sequencing Data: DRISEE.” *PLOS
      Comput Biol* 8 (6): e1002541.

   .. container::
      :name: ref-BLAT

      Kent, W. J. 2002. “BLAT–the BLAST-Like Alignment Tool.” *Genome
      Res* 12 (4): 656–64.

   .. container::
      :name: ref-BOWTIE

      Langmead, B., C. Trapnell, M. Pop, and S. L. Salzberg. 2009.
      “Ultrafast and Memory-Efficient Alignment of Short DNA Sequences
      to the Human Genome.” *Genome Biol* 10 (3): R25.

   .. container::
      :name: ref-LOMAN

      Loman, Nicholas J., Raju V. Misra, Timothy J. Dallman, Chrystala
      Constantinidou, Saheer E Gharbia, John Wain, and Mark J. Pallen.
      2012. “Performance Comparison of Benchtop High-Throughput
      Sequencing Platforms.” *Nature Biotechnology* 30 (5): 434–39.
      https://doi.org/10.1038/nbt.2198.

   .. container::
      :name: ref-UNIPROT

      Magrane, Michele, and UniProt Consortium. 2011. “UniProt
      Knowledgebase: A Hub of Integrated Protein Data.” *Database: The
      Journal of Biological Databases and Curation* 2011 (January).
      https://doi.org/10.1093/database/bar009.

   .. container::
      :name: ref-IMG

      Markowitz, V. M., N. N. Ivanova, E. Szeto, K. Palaniappan, K. Chu,
      D. Dalevi, I. M. Chen, et al. 2008. “IMG/M: A Data Management and
      Analysis System for Metagenomes.” *Nucleic Acids Res* 36 (Database
      issue): D534–8.

   .. container::
      :name: ref-BIOM

      McDonald, D., J. C. Clemente, J. Kuczynski, J. Rideout, J.
      Stombaugh, D. Wendel, A. Wilke, S. Huse, J. Hufnagle, and F.
      Meyer. 2012. “The Biological Observation Matrix (BIOM) Format or:
      How I Learned to Stop Worrying and Love the Ome-Ome.”
      *Gigascience*.

   .. container::
      :name: ref-MG-RAST

      Meyer, F., D. Paarmann, M. D’Souza, R. Olson, E. M. Glass, M.
      Kubal, T. Paczian, et al. 2008. “The Metagenomics RAST Server - a
      Public Resource for the Automatic Phylogenetic and Functional
      Analysis of Metagenomes.” *BMC Bioinformatics* 9 (1): 386.
      https://doi.org/10.1186/1471-2105-9-386.

   .. container::
      :name: ref-KRONA

      Ondov, B. D., N. H. Bergman, and A. M. Phillippy. 2011.
      “Interactive Metagenomic Visualization in a Web Browser.” *BMC
      Bioinformatics* 12: 385.

   .. container::
      :name: ref-SUBSYSTEMS

      Overbeek, R., T. Begley, R. M. Butler, J. V. Choudhuri, N. Diaz,
      H.-Y. Chuang, M. Cohoon, et al. 2005. “The Subsystems Approach to
      Genome Annotation and Its Use in the Project to Annotate 1000
      Genomes.” *Nucleic Acids Res* 33 (17).

   .. container::
      :name: ref-SILVA

      Pruesse, Elmar, Christian Quast, Katrin Knittel, Bernhard M.
      Fuchs, Wolfgang Ludwig, Jörg Peplies, and Frank Oliver O.
      Glöckner. 2007. “SILVA: A Comprehensive Online Resource for
      Quality Checked and Aligned Ribosomal RNA Sequence Data Compatible
      with ARB.” *Nucleic Acids Research* 35 (21): 7188–96.
      https://doi.org/10.1093/nar/gkm864.

   .. container::
      :name: ref-REFSEQ

      Pruitt, K. D., T. Tatusova, and D. R. Maglott. 2007. “NCBI
      Reference Sequences (RefSeq): A Curated Non-Redundant Sequence
      Database of Genomes, Transcripts and Proteins.” *Nucleic Acids
      Res* 35 (Database issue).
      http://view.ncbi.nlm.nih.gov/pubmed/17130148.

   .. container::
      :name: ref-GCDML

      R., Kottmann, Gray T., Murphy S., Kagan L., Kravitz S., Lombardot
      T., Field D., and Glöckner FO; Genomic Standards Consortium. 2008.
      “A Standard MIGS/MIMS Compliant XML Schema: Toward the Development
      of the Genomic Contextual Data Markup Language (GCDML).” *OMICS*
      12 (2): 115–21. https://doi.org/10.1089/omi.2008.0A10.

   .. container::
      :name: ref-RARE

      Reeder, J., and R. Knight. 2009. “The ‘Rare Biosphere’: A Reality
      Check.” *Nat Methods* 6 (9): 636–7.

   .. container::
      :name: ref-FGS

      Rho, Mina, Haixu Tang, and Yuzhen Ye. 2010. “FragGeneScan:
      Predicting Genes in Short and Error-Prone Reads.” *Nucleic Acids
      Research* 38 (20): e191–e191.

   .. container::
      :name: ref-MGREVIEW

      Riesenfeld, C. S., P. D. Schloss, and J. Handelsman. 2004.
      “Metagenomics: Genomic Analysis of Microbial Communities.” *Annu
      Rev Genet* 38: 525–52.

   .. container::
      :name: ref-PATRIC

      Snyder, E. E., N. Kampanya, J. Lu, E. K. Nordberg, H. R. Karur, M.
      Shukla, J. Soneja, et al. 2007. “PATRIC: The VBI PathoSystems
      Resource Integration Center.” *Nucleic Acids Res* 35 (Database
      issue). https://doi.org/10.1093/nar/gkl858.

   .. container::
      :name: ref-1584883278

      Speed, Terry. 2003. *Statistical Analysis of Gene Expression
      Microarray Data*. Chapman; Hall/CRC.
      http://www.amazon.com/Statistical-Analysis-Gene-Expression-Microarray/dp/1584883278/.

   .. container::
      :name: ref-COG

      Tatusov, R. L., N. D. Fedorova, J. D. Jackson, A. R. Jacobs, B.
      Kiryutin, E. V. Koonin, D. M. Krylov, et al. 2003. “The COG
      Database: An Updated Version Includes Eukaryotes.” *BMC
      Bioinformatics* 4: 41.

   .. container::
      :name: ref-THOMASREVIEW

      Thomas, Torsten, Jack Gilbert, and Folker Meyer. 2012.
      “Metagenomics - a Guide from Sampling to Data Analysis.”
      *Microbial Informatics and Experimentation* 2 (1): 3.
      https://doi.org/10.1186/2042-5783-2-3.

   .. container::
      :name: ref-TRIMBLE_SHORT

      Trimble, W. L., K. P. Keegan, M. D’Souza, A. Wilke, J. Wilkening,
      J. Gilbert, and F. Meyer. 2012. “Short-Read Reading-Frame
      Predictors Are Not Created Equal: Sequence Error Causes Loss of
      Signal.” *BMC Bioinformatics* 13 (1): 183.

   .. container::
      :name: ref-M5NR

      Wilke, A., T. Harrison, J. Wilkening, D. Field, E. M. Glass, N.
      Kyrpides, K. Mavrommatis, and F. Meyer. 2012. “The M5nr: A Novel
      Non-Redundant Database Containing Protein Sequences and
      Annotations from Multiple Sources and Associated Tools.” *BMC
      Bioinformatics* 13: 141.

   .. container::
      :name: ref-SHOCK

      Wilke, Andreas, Wolfgang Gerlach, Travis Harrison, Tobias Paczian,
      Wei Tang, William L. Trimble, Jared Wilkening, Narayan Desai, and
      Folker Meyer. 2015. “Shock: Active Storage for Multicloud
      Streaming Data Analysis.” In *2nd IEEE/ACM International Symposium
      on Big Data Computing, BDC 2015, Limassol, Cyprus, December 7-10,
      2015*, edited by Ioan Raicu, Omer F. Rana, and Rajkumar Buyya,
      68–72. IEEE. https://doi.org/10.1109/BDC.2015.40.

   .. container::
      :name: ref-AWE

      Wilke, A., J. Wilkening, E. M. Glass, N. Desai, and F. Meyer.
      2011. “An Experience Report: Porting the MG-RAST Rapid
      Metagenomics Analysis Pipeline to the Cloud.” *Concurrency and
      Computation: Practice and Experience* 23 (17): 2250–7.

   .. container::
      :name: ref-MGCLOUD

      Wilkening, J., A. Wilke, N. Desai, and F. Meyer. 2009. “Using
      Clouds for Metagenomics: A Case Study.” In *IEEE Cluster 2009*.

   .. container::
      :name: ref-MIENS

      Yilmaz, Pelin, Renzo Kottmann, Dawn Field, Rob Knight, James Cole,
      Linda Amaral-Zettler, Jack Gilbert, et al. 2010. “The ‘Minimum
      Information About an ENvironmental Sequence’ (MIENS)
      Specification.” *Nature Biotechnology*.

.. [1]
   This includes only the computation cost, no data transfer cost, and
   was computed using 2009 prices.

.. [2]
   We use the term *cloud* as a shortcut for Infrastructure as a Service
   (IaaS).

.. [3]
   This would be for several metagenomes that are part of the JGI
   Prairie pilot.

.. [4]
   An MD5 checksum is a widely used way to create a digital fingerprint
   for a file. Think of it as a kind of checksum, if the fingerprint
   changed, so did the file. The fingerprints are easy to compare. There
   are many tools out there for creating MD5 checksums, google is your
   friend.
