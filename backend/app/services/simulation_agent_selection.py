"""
模拟 Agent 候选筛选器

用途：
1. 从图谱实体中筛出“适合扮演社交/信息主体”的节点
2. 过滤明显不应成为 Agent 的数值、时间、token、价格、文本块等伪实体
3. 对候选 Agent 做轻量排序和数量上限控制，避免模拟成本失控
"""

import re
from typing import Dict, List, Tuple

from .zep_entity_reader import EntityNode


# 更适合在社交/信息传播模拟中充当主体的实体类型
PREFERRED_AGENT_ENTITY_TYPES = {
    "person",
    "publicfigure",
    "expert",
    "journalist",
    "official",
    "professor",
    "student",
    "alumni",
    "organization",
    "institution",
    "company",
    "consumerelectronicscompany",
    "retailer",
    "certificationlaboratory",
    "governmentagency",
    "mediaoutlet",
    "technologyblog",
    "marketdataplatform",
    "webarchiveservice",
    "mapsource",
    "militaryforce",
    "ngo",
    "community",
    "group",
}


# 一般不应直接作为 Agent 的实体类型
EXCLUDED_AGENT_ENTITY_TYPES = {
    "textentry",
    "concept",
    "object",
    "time",
    "deadline",
    "location",
    "place",
    "event",
}


DEFAULT_MAX_AGENT_CANDIDATES = 24


_HEX_RE = re.compile(r"^[0-9a-f]{24,}$", re.IGNORECASE)
_DECIMAL_RE = re.compile(r"^[+-]?\d+(\.\d+)?$")
_TIMESTAMP_RE = re.compile(r"^\d{4}-\d{2}-\d{2}(t\d{2}:\d{2}(:\d{2})?z?)?$", re.IGNORECASE)
_DATE_CN_RE = re.compile(r"^\d{1,2}月\d{1,2}日")
_LONG_DIGITS_RE = re.compile(r"^\d{8,}$")
_ODDS_LABEL_RE = re.compile(r"^(yes|no|spread|liquidity|odds|price|probability)$", re.IGNORECASE)


def _norm_type(entity: EntityNode) -> str:
    return (entity.get_entity_type() or "").strip().lower()


def _norm_name(entity: EntityNode) -> str:
    return (entity.name or "").strip()


def _looks_like_pure_number(name: str) -> bool:
    compact = name.replace(",", "").strip()
    return bool(compact) and bool(_DECIMAL_RE.fullmatch(compact))


def _looks_like_date_or_time(name: str) -> bool:
    compact = name.strip()
    return bool(_TIMESTAMP_RE.fullmatch(compact) or _DATE_CN_RE.match(compact))


def _looks_like_token_or_hash(name: str) -> bool:
    compact = name.strip().lower()
    return bool(_HEX_RE.fullmatch(compact) or _LONG_DIGITS_RE.fullmatch(compact))


def _looks_like_metric_label(name: str) -> bool:
    compact = name.strip()
    if not compact:
        return False
    lowered = compact.lower()
    if _ODDS_LABEL_RE.fullmatch(lowered):
        return True
    return any(
        token in lowered
        for token in [
            "token history",
            "fidelity=",
            "timestamp",
            "odds",
            "spread",
            "liquidity",
            "price",
            "probability",
            "market_signal",
            "time_series",
            "clob",
            "yes token",
        ]
    )


def classify_exclusion_reason(entity: EntityNode) -> str:
    entity_type = _norm_type(entity)
    name = _norm_name(entity)

    if entity_type in EXCLUDED_AGENT_ENTITY_TYPES:
        return f"excluded_type:{entity_type}"
    if _looks_like_pure_number(name):
        return "numeric_name"
    if _looks_like_date_or_time(name):
        return "date_or_time_name"
    if _looks_like_token_or_hash(name):
        return "token_or_hash_name"
    if _looks_like_metric_label(name):
        return "market_metric_name"
    if not name:
        return "empty_name"
    return ""


def is_valid_agent_candidate(entity: EntityNode) -> bool:
    reason = classify_exclusion_reason(entity)
    if reason:
        return False

    entity_type = _norm_type(entity)
    if entity_type in PREFERRED_AGENT_ENTITY_TYPES:
        return True

    # 对未知类型保守处理：只有名字像主体且存在一定上下文时才保留
    if entity_type and entity_type not in EXCLUDED_AGENT_ENTITY_TYPES:
        return bool(
            (getattr(entity, "summary", "") or "")
            or (getattr(entity, "related_edges", []) or [])
            or (getattr(entity, "related_nodes", []) or [])
        )

    return False


def _entity_score(entity: EntityNode) -> float:
    entity_type = _norm_type(entity)
    name = _norm_name(entity)
    related_edges = getattr(entity, "related_edges", []) or []
    related_nodes = getattr(entity, "related_nodes", []) or []
    summary = getattr(entity, "summary", "") or ""

    score = 0.0
    if entity_type in PREFERRED_AGENT_ENTITY_TYPES:
        score += 5.0
    if entity_type in {
        "governmentagency",
        "mediaoutlet",
        "marketdataplatform",
        "mapsource",
        "militaryforce",
        "organization",
        "person",
    }:
        score += 2.0

    score += min(len(related_edges), 10) * 0.5
    score += min(len(related_nodes), 10) * 0.2
    score += min(len(summary), 400) / 200.0

    if len(name) >= 3 and not _looks_like_pure_number(name):
        score += 1.0

    return score


def filter_agent_candidates(
    entities: List[EntityNode],
    max_candidates: int = DEFAULT_MAX_AGENT_CANDIDATES,
) -> Tuple[List[EntityNode], Dict[str, object]]:
    """
    对图谱实体进行 Agent 候选筛选。

    Returns:
        (selected_entities, stats)
    """
    kept: List[EntityNode] = []
    excluded_reasons: Dict[str, int] = {}

    for entity in entities:
        reason = classify_exclusion_reason(entity)
        if reason:
            excluded_reasons[reason] = excluded_reasons.get(reason, 0) + 1
            continue
        if not is_valid_agent_candidate(entity):
            excluded_reasons["not_social_actor"] = excluded_reasons.get("not_social_actor", 0) + 1
            continue
        kept.append(entity)

    kept.sort(key=_entity_score, reverse=True)

    truncated = 0
    if max_candidates > 0 and len(kept) > max_candidates:
        truncated = len(kept) - max_candidates
        kept = kept[:max_candidates]

    selected_types = sorted({_norm_type(entity) or "unknown" for entity in kept})

    stats: Dict[str, object] = {
        "input_count": len(entities),
        "selected_count": len(kept),
        "truncated_count": truncated,
        "excluded_count": len(entities) - len(kept),
        "selected_types": selected_types,
        "excluded_reasons": excluded_reasons,
        "max_candidates": max_candidates,
    }
    return kept, stats
