# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

FROM gcr.io/oss-fuzz-base/base-builder-rust-llvm
RUN apt-get update && apt-get install -y make autoconf automake libtool m4 libclang1 dosfstools ntfs-3g
RUN git clone --depth 1 https://github.com/google/rrg.git
RUN cd $SRC/rrg && git submodule update --init
COPY build.sh $SRC/
WORKDIR $SRC/rrg
