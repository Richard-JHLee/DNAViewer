#!/bin/bash

# DNAViewer Gene Library API 테스트 스크립트
# Gene 선택 시 그룹별 염기서열 데이터를 가져오는 API 호출 테스트

echo "======================================================================"
echo "DNAViewer - Gene Library API 테스트"
echo "======================================================================"
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트할 유전자 목록 (Gene ID:Symbol:Accession)
genes=(
    "672:BRCA1:NM_007294.4"
    "7157:TP53:NM_000546.6"
    "1080:CFTR:NM_000492.4"
    "348:APOE:NM_000041.4"
    "3043:HBB:NM_000518.5"
)

# 각 유전자 테스트
for gene_info in "${genes[@]}"; do
    IFS=':' read -r gene_id symbol accession <<< "$gene_info"
    
    echo ""
    echo "======================================================================"
    echo -e "${BLUE}🧬 $symbol (Gene ID: $gene_id)${NC}"
    echo "======================================================================"
    
    # Step 1: Gene ID → Nucleotide Accession 찾기
    echo ""
    echo -e "${YELLOW}Step 1: Gene ID → Nucleotide Accession 변환${NC}"
    echo "curl https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=gene&db=nuccore&id=$gene_id&retmode=json"
    echo ""
    
    link_result=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=gene&db=nuccore&id=$gene_id&retmode=json")
    
    # RefSeq mRNA 링크 개수 확인
    refseq_count=$(echo "$link_result" | grep -o 'gene_nuccore_refseqrna' | wc -l)
    echo -e "${GREEN}✓ RefSeq mRNA 링크 발견: $refseq_count 개${NC}"
    
    # Step 2: Nucleotide Accession → 염기서열 가져오기
    echo ""
    echo -e "${YELLOW}Step 2: 염기서열 가져오기 ($accession)${NC}"
    echo "curl https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$accession&rettype=fasta&retmode=text"
    echo ""
    
    sequence_result=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$accession&rettype=fasta&retmode=text")
    
    # 헤더 출력
    header=$(echo "$sequence_result" | head -1)
    echo -e "${GREEN}✓ FASTA 헤더:${NC}"
    echo "  $header"
    
    # 염기서열 길이 계산
    sequence=$(echo "$sequence_result" | grep -v "^>" | tr -d '\n')
    length=${#sequence}
    
    echo ""
    echo -e "${GREEN}✓ 염기서열 길이: $(printf "%'d" $length) bp${NC}"
    
    # 그룹 계산
    group_size=100
    total_groups=$(( (length + group_size - 1) / group_size ))
    
    echo -e "${GREEN}✓ 총 그룹 수: $total_groups groups (각 ${group_size}bp)${NC}"
    
    # 그룹 구성 예시
    echo ""
    echo "그룹 구성 예시:"
    echo "  • G1: 0-99 bp"
    if [ $total_groups -gt 1 ]; then
        echo "  • G2: 100-199 bp"
    fi
    if [ $total_groups -gt 2 ]; then
        echo "  • G3: 200-299 bp"
    fi
    if [ $total_groups -gt 3 ]; then
        echo "  • ..."
        last_start=$(( (total_groups - 1) * group_size ))
        last_end=$(( length - 1 ))
        echo "  • G$total_groups: $last_start-$last_end bp"
    fi
    
    # 첫 100bp 출력
    echo ""
    echo "첫 100bp (G1):"
    first_100=$(echo "$sequence" | cut -c1-100)
    # 70자씩 줄바꿈
    echo "$first_100" | fold -w 70 | sed 's/^/  /'
    
    # 염기 조성 분석
    a_count=$(echo "$sequence" | grep -o "A" | wc -l)
    t_count=$(echo "$sequence" | grep -o "T" | wc -l)
    g_count=$(echo "$sequence" | grep -o "G" | wc -l)
    c_count=$(echo "$sequence" | grep -o "C" | wc -l)
    
    if [ $length -gt 0 ]; then
        a_pct=$(awk "BEGIN {printf \"%.1f\", ($a_count / $length) * 100}")
        t_pct=$(awk "BEGIN {printf \"%.1f\", ($t_count / $length) * 100}")
        g_pct=$(awk "BEGIN {printf \"%.1f\", ($g_count / $length) * 100}")
        c_pct=$(awk "BEGIN {printf \"%.1f\", ($c_count / $length) * 100}")
        gc_content=$(awk "BEGIN {printf \"%.1f\", (($g_count + $c_count) / $length) * 100}")
        
        echo ""
        echo "염기 조성:"
        echo "  A: $(printf "%'d" $a_count) ($a_pct%)"
        echo "  T: $(printf "%'d" $t_count) ($t_pct%)"
        echo "  G: $(printf "%'d" $g_count) ($g_pct%)"
        echo "  C: $(printf "%'d" $c_count) ($c_pct%)"
        echo -e "  ${GREEN}GC Content: $gc_content%${NC}"
    fi
    
    # 3초 대기 (NCBI rate limiting: 3 req/sec)
    sleep 0.4
done

echo ""
echo "======================================================================"
echo -e "${GREEN}✅ 모든 테스트 완료!${NC}"
echo "======================================================================"
echo ""
echo "📝 자세한 정보는 GENE_SEQUENCE_API_GUIDE.md 파일을 참조하세요."
echo ""

