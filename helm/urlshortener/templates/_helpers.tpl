{{/*
Nhãn chuẩn (Standard Labels) dùng chung cho tất cả tài nguyên trong Helm Chart
*/}}
{{- define "urlshortener.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: url-shortener-infra
{{- end }}
