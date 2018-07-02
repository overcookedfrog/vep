FROM alpine:3.7 as builder
RUN apk add --update curl wget git unzip alpine-sdk perl perl-dbd-mysql perl-archive-zip perl-json perl-io-gzip zlib-dev bzip2-dev xz-dev
RUN apk add perl-module-build perl-capture-tiny perl-dev
RUN curl -L https://cpanmin.us | perl - App::cpanminus
RUN cpanm Set::IntervalTree

RUN set -ex \
    && curl -L -O https://github.com/samtools/htslib/releases/download/1.7/htslib-1.7.tar.bz2 \
    && tar jxf htslib-1.7.tar.bz2 \
    && cd htslib-1.7 \
    && ./configure \
    && make

RUN set -ex \
    && git clone https://github.com/Ensembl/ensembl-vep.git \
    && cd ensembl-vep \
    && git checkout -b release/91.1 release/91.1 \
    && perl INSTALL.pl -a al -l -n \
    && rm -rf examples travisci t docker INSTALL.pl README.md cpanfile


FROM alpine:3.7
ENV PATH /app/ensembl-vep:$PATH
RUN apk add --update perl libstdc++ zlib libbz2 xz-libs
COPY --from=builder /usr/lib/perl5 /usr/lib/perl5
COPY --from=builder /usr/local/lib/perl5/site_perl /usr/local/lib/perl5/site_perl
COPY --from=builder /htslib-1.7/bgzip /usr/local/bin/bgzip
COPY --from=builder /htslib-1.7/tabix /usr/local/bin/tabix
COPY --from=builder /ensembl-vep /app/ensembl-vep
