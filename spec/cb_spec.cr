require "./spec_helper"
include CB

Spectator.describe CB do
  describe "IDENT_PATTERN" do
    subject { IDENT_PATTERN.matches? str }
    provided str: "abc" { expect { subject }.to be_true }
    provided str: "a_b_c" { expect { subject }.to be_false }
  end

  describe "API_NAME_PATTERN" do
    subject { API_NAME_PATTERN.matches? str }
    provided str: "abc" { expect { subject }.to be_false }
    provided str: "abcde" { expect { subject }.to be_true }
    provided str: "abc 2022/05/09" { expect { subject }.to be_true }
  end
end
